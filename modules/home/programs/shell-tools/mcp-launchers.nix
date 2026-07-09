# Title         : mcp-launchers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/mcp-launchers.nix
# ----------------------------------------------------------------------------
# MCP fleet owner: builds pinned pnpm launchers from mcp-fleet.nix rows and
# ships `forge-mcp` (outdated|doctor|drift), the fleet health surface. Bump a
# row's version to roll its server; drift validates both client registrations
# against the manifest and only reports; pnpm output routes to stderr so the
# MCP stdio channel stays clean.
{
  config,
  lib,
  pkgs,
  ...
}: let
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  fleet = import ./mcp-fleet.nix {
    inherit profileBin;
    homeDir = config.home.homeDirectory;
  };
  launcherRows = builtins.filter (r: r ? launcher) fleet;
  fleetJson = pkgs.writeText "mcp-fleet.json" (builtins.toJSON fleet);
  mkLauncher = row: name:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [pkgs.coreutils pkgs.nodejs-bin_26 pkgs.pnpm_11];
      text = ''
        ${row.launcher.prelude or ""}prefix="''${XDG_CACHE_HOME:-$HOME/.cache}/forge-mcp/${row.launcher.pkg}/${row.launcher.version}"
        entry="$prefix/node_modules/.bin/${row.launcher.bin}"
        if [ ! -x "$entry" ]; then
          # Stage-then-rename: fleet clients spawn every server at once, so first
          # installs race. Each racer stages privately; the rename winner owns the
          # prefix, losers discard their stage and exec the winner's tree.
          parent="$(dirname "$prefix")"
          mkdir -p "$parent"
          stage="$(mktemp -d "$parent/.stage.XXXXXX")"
          # Failure litter guard: an errexit death mid-install must not strand
          # the stage; every success path removes or promotes it first.
          trap 'rm -rf "$stage"' EXIT
          # --config rows pin XDG containment for launchd spawns without session
          # env; prefer-offline lets exact pins cold-start from a warm store.
          pnpm add --dir "$stage" \
            --config.loglevel=error \
            --config.prefer-offline=true \
            --config.store-dir="''${XDG_DATA_HOME:-$HOME/.local/share}/pnpm/store" \
            --config.cache-dir="''${XDG_CACHE_HOME:-$HOME/.cache}/pnpm" \
            --config.state-dir="''${XDG_STATE_HOME:-$HOME/.local/state}/pnpm" \
            "${row.launcher.pkg}@${row.launcher.version}" >&2 || true
          # Success predicate is the staged bin, not pnpm's exit status: a node
          # teardown crash after full materialization must not kill cold-start,
          # and a tree missing its bin must never be promoted to the prefix.
          if [ -x "$entry" ]; then
            rm -rf "$stage"
          elif [ -x "$stage/node_modules/.bin/${row.launcher.bin}" ]; then
            # mv first: a prefix a racer just promoted must never be deleted.
            # Only a still-corrupt prefix is cleared, then one retry.
            if ! mv -T "$stage" "$prefix" 2>/dev/null; then
              if [ -x "$entry" ]; then
                rm -rf "$stage"
              else
                rm -rf "$prefix"
                mv -T "$stage" "$prefix" 2>/dev/null || rm -rf "$stage"
              fi
            fi
          else
            rm -rf "$stage"
            echo "${name}: pnpm add ${row.launcher.pkg}@${row.launcher.version} materialized no executable ${row.launcher.bin}" >&2
            exit 69
          fi
        fi
        exec "$entry" "$@"
      '';
    };
  launchers = lib.concatMap (row: map (mkLauncher row) row.launcher.names) launcherRows;
  # Maghz postgres MCP: DSN via MAGHZ_MCP__DATABASE_URI with launchd GUI replay
  # fallback; loud exit 78 when unresolved so required-server failure is visible.
  maghzPostgres = pkgs.writeShellApplication {
    name = "forge-maghz-postgres-mcp";
    runtimeInputs = [pkgs.uv];
    text = ''
      if [ -z "''${MAGHZ_MCP__DATABASE_URI:-}" ] && [ -x /bin/launchctl ]; then
        MAGHZ_MCP__DATABASE_URI="$(/bin/launchctl getenv MAGHZ_MCP__DATABASE_URI || true)"
        export MAGHZ_MCP__DATABASE_URI
      fi
      if [ -z "''${MAGHZ_MCP__DATABASE_URI:-}" ]; then
        echo "postgres-mcp: MAGHZ_MCP__DATABASE_URI is unset; replay Forge GUI secrets (gui-op-secrets) and confirm the maghz tunnel" >&2
        exit 78
      fi
      DATABASE_URI="$MAGHZ_MCP__DATABASE_URI" UV_PYTHON_DOWNLOADS=automatic \
        exec uvx --python 3.13 postgres-mcp --access-mode=restricted "$@"
    '';
  };
  # Rhino's package manager owns the router install; version-globbing keeps
  # client configs stable across McNeel package updates. Lifecycle gate: the
  # heavy vendor router spawns only while Rhino 9 WIP runs; otherwise a stdio
  # shim serves one rhino_status tool (start Rhino, then reconnect). The
  # supervised lane owns the router's process group — client TERM/HUP or a
  # dead client (wrapper reparented to launchd) tears the subtree down, so no
  # session exit strands a router; the vendor binary exposes no idle-exit.
  rhinoRouter = pkgs.writeShellApplication {
    name = "rhino-mcp-router";
    runtimeInputs = [pkgs.coreutils pkgs.jq];
    text = ''
      rhino_bin="''${RHINO_MCP_HOST_BINARY:-/Applications/RhinoWIP.app/Contents/MacOS/Rhinoceros}"

      if /usr/bin/pgrep -qf "$rhino_bin"; then
        base="$HOME/Library/Application Support/McNeel/Rhinoceros/packages/9.0/Rhino-MCP-Platform"
        entry="$(printf '%s\n' "$base"/*/router/osx-arm64/rhino-mcp-router | sort -V | tail -1)"
        if [ ! -x "$entry" ]; then
          echo "rhino-mcp-router: no Rhino-MCP-Platform package under $base" >&2
          exit 69
        fi
        set -m
        "$entry" "$@" <&0 &
        router=$!
        set +m
        reap() {
          kill -TERM -- "-$router" 2>/dev/null || kill -TERM "$router" 2>/dev/null || true
        }
        trap reap TERM INT HUP
        # Orphan watchdog: an empty or launchd ppid means the MCP client died
        # without reaping the wrapper; take the router subtree down with it.
        (
          while kill -0 "$router" 2>/dev/null; do
            pp="$(/bin/ps -o ppid= -p $$ 2>/dev/null | tr -d ' ')"
            if [ -z "$pp" ] || [ "$pp" = 1 ]; then
              kill -TERM -- "-$router" 2>/dev/null || true
              sleep 2
              kill -KILL -- "-$router" 2>/dev/null || true
              exit 0
            fi
            sleep 15
          done
        ) &
        wdog=$!
        rc=0
        wait "$router" || rc=$?
        reap
        for _ in 1 2 3; do
          kill -0 "$router" 2>/dev/null || break
          sleep 1
        done
        kill -KILL -- "-$router" 2>/dev/null || true
        kill "$wdog" 2>/dev/null || true
        exit "$rc"
      fi

      # Thin responder: newline-delimited JSON-RPC over stdio at near-zero
      # cost. tools/call re-probes Rhino so an agent that started it mid-
      # session reads live state plus the reconnect instruction; stdin EOF
      # is the shutdown, so the shim can never outlive its client.
      status_text() {
        if /usr/bin/pgrep -qf "$rhino_bin"; then
          printf 'Rhino is running but this MCP connection predates it. Reconnect the rhino-mcp-platform server (/mcp -> reconnect, or restart the session) to spawn the router and load the full toolset.'
        else
          printf 'Rhino 9 WIP is not running; the rhino-mcp-platform router spawns only against a live Rhino. Start it (open -a RhinoWIP), wait for the app to finish loading, then reconnect the rhino-mcp-platform server (/mcp -> reconnect, or restart the session) to load the full toolset.'
        fi
      }
      tools_json='{"tools":[{"name":"rhino_status","description":"Reports the Rhino MCP gate: the full rhino-mcp-platform toolset loads only while Rhino 9 WIP runs. Call this to learn how to bring the toolset up.","inputSchema":{"type":"object","properties":{}}}]}'
      while IFS= read -r line; do
        [ -n "$line" ] || continue
        method="$(jq -r '.method // empty' <<<"$line" 2>/dev/null || true)"
        id="$(jq -c 'if has("id") then .id else empty end' <<<"$line" 2>/dev/null || true)"
        case "$method" in
          initialize)
            [ -n "$id" ] || continue
            pv="$(jq -r '.params.protocolVersion // "2025-06-18"' <<<"$line" 2>/dev/null || printf '2025-06-18')"
            jq -cn --argjson id "$id" --arg pv "$pv" \
              '{jsonrpc: "2.0", id: $id, result: {protocolVersion: $pv, capabilities: {tools: {}}, serverInfo: {name: "rhino-mcp-gate", version: "1.0.0"}}}'
            ;;
          tools/list)
            [ -n "$id" ] || continue
            jq -cn --argjson id "$id" --argjson t "$tools_json" '{jsonrpc: "2.0", id: $id, result: $t}'
            ;;
          tools/call)
            [ -n "$id" ] || continue
            jq -cn --argjson id "$id" --arg text "$(status_text)" \
              '{jsonrpc: "2.0", id: $id, result: {content: [{type: "text", text: $text}], isError: true}}'
            ;;
          ping)
            [ -n "$id" ] || continue
            jq -cn --argjson id "$id" '{jsonrpc: "2.0", id: $id, result: {}}'
            ;;
          notifications/* | "") : ;;
          *)
            [ -n "$id" ] || continue
            jq -cn --argjson id "$id" \
              '{jsonrpc: "2.0", id: $id, error: {code: -32601, message: "rhino-mcp-gate: method unavailable while Rhino is down; call rhino_status"}}'
            ;;
        esac
      done
    '';
  };
  # The row's updateEngine selects the probe set: only npm-registry rows feed
  # the npm-latest check; a manual/other engine row never emits a false pin row.
  pins =
    builtins.concatStringsSep "\n" (map (r: "${r.launcher.pkg}|${r.launcher.version}")
      (builtins.filter (r: r.launcher.updateEngine == "npm-registry") launcherRows));
  # Drift program: fleet rows vs live client registrations, key NAMES only.
  driftJq = pkgs.writeText "mcp-drift.jq" ''
    ($fleet[0]) as $rows
    | ($claude[0] // {}) as $cl
    | ($codex[0] // {}) as $cx
    | [
        $rows[] as $row
        | ($row.clients // ["claude", "codex"]) as $who
        | ($row.assertLevel // "full") as $lvl
        | (
            (if ($who | index("claude")) | not then []
             elif $cl[$row.name] == null then ["\($row.name): MISSING in claude"]
             elif $lvl == "presence" then []
             else ($cl[$row.name]) as $c
              | (if $row.transport == "stdio" then
                  (if ($c.type // "stdio") != "stdio" then ["\($row.name): claude type != stdio"] else [] end)
                  + (if ($c.command // "") != $row.command then ["\($row.name): claude command \($c.command // "absent") != \($row.command)"] else [] end)
                  + (if ($c.args // []) != ($row.args // []) then ["\($row.name): claude args \($c.args // [])"] else [] end)
                  + ((($c.env // {}) | keys | sort) as $have
                     | (($row.claudeEnvNames // $row.envKeys // []) | sort) as $want
                     | if $have != $want then ["\($row.name): claude env names \($have) != \($want)"] else [] end)
                else
                  (if ($c.type // "") != "http" then ["\($row.name): claude type != http"] else [] end)
                  + (if ($c.url // "") != $row.url then ["\($row.name): claude url \($c.url // "absent")"] else [] end)
                  + ((($c.headers // {}) | keys | sort) as $have
                     | (($row.headerNames // []) | sort) as $want
                     | if $have != $want then ["\($row.name): claude header names \($have) != \($want)"] else [] end)
                end)
             end)
            + (if ($who | index("codex")) | not then []
               elif $cx[$row.name] == null then ["\($row.name): MISSING in codex"]
               elif $lvl == "presence" then []
               else ($cx[$row.name]) as $c
                | (if ($c.required // false) != ($row.codex.required // false) then ["\($row.name): codex required \($c.required // false) != \($row.codex.required // false)"] else [] end)
                  + (if ($c.startup_timeout_sec // null) != $row.codex.startupTimeoutSec then ["\($row.name): codex startup_timeout_sec \($c.startup_timeout_sec // "absent")"] else [] end)
                  + (if ($c.tool_timeout_sec // null) != $row.codex.toolTimeoutSec then ["\($row.name): codex tool_timeout_sec \($c.tool_timeout_sec // "absent")"] else [] end)
                  + (if $row.transport == "stdio" then
                      (if ($c.command // "") != $row.command then ["\($row.name): codex command \($c.command // "absent") != \($row.command)"] else [] end)
                      + (if ($c.args // []) != ($row.args // []) then ["\($row.name): codex args \($c.args // [])"] else [] end)
                      + ((($c.env_vars // []) | sort) as $have
                         | (($row.envKeys // []) | sort) as $want
                         | if $have != $want then ["\($row.name): codex env_vars \($have) != \($want)"] else [] end)
                    else
                      (if ($c.url // "") != $row.url then ["\($row.name): codex url \($c.url // "absent")"] else [] end)
                      + (if ($c.bearer_token_env_var // null) != ($row.codex.bearerEnvVar // null) then ["\($row.name): codex bearer_token_env_var \($c.bearer_token_env_var // "absent")"] else [] end)
                      + (if ($c.env_http_headers // null) != ($row.codex.headerEnv // null) then ["\($row.name): codex env_http_headers drift"] else [] end)
                    end)
               end)
          )
      ]
    | flatten
    + (($cl | keys) - [$rows[] | select((.clients // ["claude", "codex"]) | index("claude")) | .name] | map("\(.): EXTRA in claude (not in manifest)"))
    + (($cx | keys) - [$rows[] | select((.clients // ["claude", "codex"]) | index("codex")) | .name] | map("\(.): EXTRA in codex (not in manifest)"))
    | .[]
  '';
  forgeMcp = pkgs.writeShellApplication {
    name = "forge-mcp";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.jq pkgs.yq-go];
    text = ''
      fleet='${fleetJson}'
      usage() { echo "usage: forge-mcp outdated [--notify] | doctor [--network] [--json] | drift" >&2; exit 64; }
      verb="''${1:-}"; shift || true

      cmd_outdated() {
        notify=0; [ "''${1:-}" != "--notify" ] || notify=1
        rc=0 out=""
        while IFS="|" read -r pkg version; do
          if latest="$(curl -fsS --max-time 20 "https://registry.npmjs.org/$(jq -rn --arg p "$pkg" '$p|@uri')/latest" | jq -er .version)"; then
            if [ "$latest" != "$version" ]; then
              out="$out"$'\n'"OUTDATED $pkg pinned=$version latest=$latest"; rc=1
            else
              out="$out"$'\n'"current  $pkg $version"
            fi
          else
            # Registry/network failure is not drift: report, never notify.
            out="$out"$'\n'"unknown  $pkg $version (registry unreachable)"
          fi
        done < <(printf '%s\n' '${pins}')
        printf '%s\n' "''${out#?}"
        if [ "$notify" = 1 ] && [ "$rc" = 1 ]; then
          n="$(printf '%s\n' "$out" | grep -c '^OUTDATED' || true)"
          /usr/bin/osascript -e "display notification \"$n MCP pin(s) behind npm latest - run forge-mcp outdated\" with title \"Forge MCP pins\"" || true
        fi
        exit "$rc"
      }

      # Side-effect-free health probe: newline-delimited JSON-RPC initialize on
      # stdio (stdin EOF is the shutdown), POST initialize for http rows. Env
      # material is asserted by key NAME only; values never print. Each probe
      # emits one typed row (STATUS<TAB>name<TAB>detail); presentation is the
      # doctor's, so human and --json render from the same rows.
      req='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"forge-mcp-doctor","version":"1.0.0"}}}'
      probe_row() {
        row="$1" network="$2" out="$3"
        # One jq projection owns the row header; unit-separator join survives
        # empty fields where tab-IFS reads would collapse them.
        IFS=$'\x1f' read -r name probe transport t < <(jq -r \
          '[.name, .probe, .transport, (.codex.startupTimeoutSec // 20 | tostring)] | join("\u001f")' <<<"$row")
        missing="$(jq -r '(.envKeys // [])[]' <<<"$row" | while IFS= read -r k; do
          [ -n "''${!k:-}" ] || printf '%s ' "$k"
        done)"
        envnote=""; [ -z "$missing" ] || envnote=" env-missing: $missing"
        emit() { printf '%s\t%s\t%s\n' "$1" "$name" "$2" >"$out"; }
        if [ "$probe" = "skip" ]; then
          emit SKIP "host-private row"; return 0
        fi
        if [ "$probe" = "network" ] && [ "$network" != 1 ]; then
          emit SKIP "network class (probe with --network)$envnote"; return 0
        fi
        if [ "$transport" = "stdio" ]; then
          cmdpath="$(jq -r '.command' <<<"$row")"
          if [ ! -x "$cmdpath" ]; then
            emit FAIL "command not executable: $cmdpath"; return 0
          fi
          mapfile -t argv < <(jq -r '(.args // [])[]' <<<"$row")
          # FIFO stdin: hold the write end open until the response lands, then
          # close it — stdin EOF is the shutdown, so no probe outlives its
          # answer (a sleep-holder would strand every server for the full
          # timeout after doctor returns). timeout backstops mute servers.
          mkfifo "$out.fifo"
          line=""
          exec 3< <(timeout "$((t + 2))" "$cmdpath" ''${argv[0]+"''${argv[@]}"} <"$out.fifo" 2>/dev/null || true)
          exec 4>"$out.fifo"
          printf '%s\n' "$req" >&4
          IFS= read -r -t "$t" line <&3 || true
          exec 4>&-
          exec 3<&-
          rm -f "$out.fifo"
          if info="$(jq -er '.result.serverInfo | "\(.name) \(.version // "?")"' <<<"$line" 2>/dev/null)"; then
            emit OK "$info$envnote"
          else
            emit FAIL "no initialize response within ''${t}s$envnote"
          fi
        else
          url="$(jq -r '.url' <<<"$row")"
          declare -a hdr=()
          bearer="$(jq -r '.codex.bearerEnvVar // empty' <<<"$row")"
          if [ -n "$bearer" ]; then
            [ -n "''${!bearer:-}" ] || { emit SKIP "credential env absent: $bearer"; return 0; }
            hdr+=(-H "Authorization: Bearer ''${!bearer}")
          fi
          while IFS=$'\t' read -r h v; do
            [ -n "$h" ] || continue
            [ -n "''${!v:-}" ] || { emit SKIP "credential env absent: $v"; return 0; }
            hdr+=(-H "$h: ''${!v}")
          done < <(jq -r '(.codex.headerEnv // {}) | to_entries[] | "\(.key)\t\(.value)"' <<<"$row")
          body="$(mktemp)"
          # curl -w still emits its code line on transport failure; a second echo
          # would corrupt the status, so failures fall through to the 000 default.
          code="$(curl -sS --max-time "$t" -o "$body" -w '%{http_code}' -X POST "$url" \
            -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
            -H 'MCP-Protocol-Version: 2025-06-18' ''${hdr[0]+"''${hdr[@]}"} --data "$req" 2>/dev/null || true)"
          [ -n "$code" ] || code=000
          if [ "$code" = 200 ]; then
            payload="$(grep -m1 '^data:' "$body" | cut -c6- || true)"
            [ -n "$payload" ] || payload="$(cat "$body")"
            info="$(jq -er '.result.serverInfo | "\(.name) \(.version // "?")"' <<<"$payload" 2>/dev/null || echo "initialize accepted")"
            emit OK "$info$envnote"
          elif [ "$code" = 401 ] && [ ''${#hdr[@]} -eq 0 ]; then
            # No credential mechanism on the row (client-managed OAuth): a 401
            # proves the endpoint is alive; an unauthenticated pass never can.
            emit OK "reachable, HTTP 401 (client-managed auth)$envnote"
          else
            emit FAIL "HTTP $code from initialize$envnote"
          fi
          rm -f "$body"
        fi
      }

      cmd_doctor() {
        network=0 as_json=0
        for a in "$@"; do
          case "$a" in
            --network) network=1 ;;
            --json) as_json=1 ;;
            *) usage ;;
          esac
        done
        tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
        # Wrapper roll-call: every declared fleet wrapper must exist on PATH.
        while IFS= read -r w; do
          if ! command -v "$w" >/dev/null 2>&1; then
            printf 'FAIL\t%s\twrapper absent from PATH\n' "$w" >>"$tmp/wrappers"
          fi
        done < <(jq -r '.[] | (.launcher.names // [])[]' "$fleet")
        i=0
        while IFS= read -r row; do
          probe_row "$row" "$network" "$tmp/row.$i" &
          i=$((i + 1))
        done < <(jq -c '.[]' "$fleet")
        wait
        rows="$tmp/rows"
        {
          [ ! -f "$tmp/wrappers" ] || cat "$tmp/wrappers"
          for ((f = 0; f < i; f++)); do cat "$tmp/row.$f"; done
        } >"$rows"
        # Direct file grep: grep -q on the read end of a pipe SIGPIPEs the
        # writer under pipefail, and the negation would swallow real FAILs.
        rc=0
        ! grep -q $'^FAIL\t' "$rows" || rc=1
        if [ "$as_json" = 1 ]; then
          TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
          jq -Rcs --arg ts "$ts" --arg rc "$rc" '{
            ts: $ts,
            surface: "forge-mcp-doctor",
            result: (if $rc == "0" then "ok" else "fail" end),
            rows: (split("\n") | map(select(length > 0) | split("\t")
                   | {status: .[0], name: .[1], detail: .[2]}))
          }' <"$rows"
        else
          while IFS=$'\t' read -r s n d; do
            printf '[%-4s] %-20s %s\n' "$s" "$n" "$d"
          done <"$rows"
        fi
        exit "$rc"
      }

      cmd_drift() {
        # An unreadable/unparseable client config is total drift, not a crash.
        claude_json="$(jq '.mcpServers // {}' "$HOME/.claude.json" 2>/dev/null)" \
          || { echo "drift: cannot read mcpServers from ~/.claude.json"; exit 1; }
        codex_json="$(yq -p toml -o json '.mcp_servers // {}' "$HOME/.codex/config.toml" 2>/dev/null)" \
          || { echo "drift: cannot read mcp_servers from ~/.codex/config.toml"; exit 1; }
        findings="$(jq -rn \
          --slurpfile fleet "$fleet" \
          --slurpfile claude <(printf '%s' "$claude_json") \
          --slurpfile codex <(printf '%s' "$codex_json") \
          -f '${driftJq}')"
        if [ -z "$findings" ]; then
          echo "drift: clean ($(jq 'length' "$fleet") manifest rows vs claude + codex registrations)"
          exit 0
        fi
        printf '%s\n' "$findings"
        exit 1
      }

      case "$verb" in
        outdated) cmd_outdated "$@" ;;
        doctor) cmd_doctor "$@" ;;
        drift) cmd_drift "$@" ;;
        *) usage ;;
      esac
    '';
  };
in {
  home = {
    packages = launchers ++ [maghzPostgres rhinoRouter forgeMcp];

    # Hidden identity bundle: Login Items & Extensions resolves the agent's
    # AssociatedBundleIdentifiers to "Forge MCP Drift" instead of the "/bin/sh"
    # basename home-manager's mutateConfig writes into ProgramArguments[0].
    file."Applications/Forge MCP Drift.app/Contents/Info.plist".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleIdentifier</key>
        <string>com.parametric-forge.forge-mcp-drift</string>
        <key>CFBundleName</key>
        <string>Forge MCP Drift</string>
        <key>CFBundleDisplayName</key>
        <string>Forge MCP Drift</string>
        <key>CFBundleVersion</key>
        <string>1</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>LSUIElement</key>
        <true/>
        <key>LSBackgroundOnly</key>
        <true/>
      </dict>
      </plist>
    '';

    activation.registerForgeMcpDriftApp = lib.hm.dag.entryAfter ["linkGeneration"] ''
      app="$HOME/Applications/Forge MCP Drift.app"
      lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
      if [ -d "$app" ] && [ -x "$lsregister" ]; then
        "$lsregister" -f "$app" || true
      fi
    '';
  };

  # Weekly pin-drift banner: Notification Center only when a pin is outdated;
  # silent when current or offline (a registry failure never notifies).
  launchd.agents.forge-mcp-outdated = {
    enable = true;
    config = {
      # Estate label grammar: com.parametric-forge.<agent> for repo-owned jobs.
      Label = "com.parametric-forge.forge-mcp-outdated";
      ProgramArguments = ["${forgeMcp}/bin/forge-mcp" "outdated" "--notify"];
      StartCalendarInterval = [
        {
          Weekday = 1;
          Hour = 10;
          Minute = 0;
        }
      ];
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-mcp-outdated.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-mcp-outdated.log";
      AssociatedBundleIdentifiers = ["com.parametric-forge.forge-mcp-drift"];
    };
  };
}
