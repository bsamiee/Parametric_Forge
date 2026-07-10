# Title         : mcp-launchers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/mcp-launchers.nix
# ----------------------------------------------------------------------------
# CA-7 data-plane owner: builds pinned pnpm launchers from mcp-fleet.nix rows
# and ships the fleet/agent observability surface — `forge-mcp` (outdated |
# doctor | drift | generate | roots | snoop), all verbs emitting
# schema=forge-mcp/v1 JSON receipts, plus `forge-agents`, the one collector
# turning agent lanes, attention, and AI quota into cached facts the zjstatus
# bar renders. Drift reconciles five registries against the manifest owner
# (claude, codex, vscode, maghz-claude, maghz-codex) and only reports;
# `generate` is the one desired-registration generator. Bar code never
# touches providers or credentials; the collector owns that boundary.
{
  config,
  lib,
  pkgs,
  ...
}: let
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  stateHome = config.xdg.stateHome;
  inherit (config.forge.theme) roles; # Estate palette owner (modules/home/theme.nix)
  fleet = import ./mcp-fleet.nix {
    inherit profileBin;
    homeDir = config.home.homeDirectory;
  };
  launcherRows = builtins.filter (r: r ? launcher) fleet;
  fleetJson = pkgs.writeText "mcp-fleet.json" (builtins.toJSON fleet);

  # Traffic-capture policy rows (annex-gated surface): capture is unreachable
  # without the opt-in env, frames log metadata only, and files age out.
  snoopPolicy = {
    optInEnv = "FORGE_MCP_DEBUG";
    redaction = "frame-metadata-only"; # direction, method, id, kind, bytes — never params/results
    retentionDays = 7;
    logDir = "${stateHome}/forge-mcp-snoop";
  };
  # Desktop-notification policy row for the collector projections.
  notifyPolicy = {
    needsInput = true;
    minIntervalSec = 300;
  };
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
  # Full-parity drift program: fleet rows vs the two user-owned client
  # registrations, key NAMES only.
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
             elif $cl[$row.name] == null then ["claude\t\($row.name): MISSING in claude"]
             elif $lvl == "presence" then []
             else ($cl[$row.name]) as $c
              | (if $row.transport == "stdio" then
                  (if ($c.type // "stdio") != "stdio" then ["claude\t\($row.name): claude type != stdio"] else [] end)
                  + (if ($c.command // "") != $row.command then ["claude\t\($row.name): claude command \($c.command // "absent") != \($row.command)"] else [] end)
                  + (if ($c.args // []) != ($row.args // []) then ["claude\t\($row.name): claude args \($c.args // [])"] else [] end)
                  + ((($c.env // {}) | keys | sort) as $have
                     | (($row.claudeEnvNames // $row.envKeys // []) | sort) as $want
                     | if $have != $want then ["claude\t\($row.name): claude env names \($have) != \($want)"] else [] end)
                else
                  (if ($c.type // "") != "http" then ["claude\t\($row.name): claude type != http"] else [] end)
                  + (if ($c.url // "") != $row.url then ["claude\t\($row.name): claude url \($c.url // "absent")"] else [] end)
                  + ((($c.headers // {}) | keys | sort) as $have
                     | (($row.headerNames // []) | sort) as $want
                     | if $have != $want then ["claude\t\($row.name): claude header names \($have) != \($want)"] else [] end)
                end)
             end)
            + (if ($who | index("codex")) | not then []
               elif $cx[$row.name] == null then ["codex\t\($row.name): MISSING in codex"]
               elif $lvl == "presence" then []
               else ($cx[$row.name]) as $c
                | (if ($c.required // false) != ($row.codex.required // false) then ["codex\t\($row.name): codex required \($c.required // false) != \($row.codex.required // false)"] else [] end)
                  + (if ($c.startup_timeout_sec // null) != $row.codex.startupTimeoutSec then ["codex\t\($row.name): codex startup_timeout_sec \($c.startup_timeout_sec // "absent")"] else [] end)
                  + (if ($c.tool_timeout_sec // null) != $row.codex.toolTimeoutSec then ["codex\t\($row.name): codex tool_timeout_sec \($c.tool_timeout_sec // "absent")"] else [] end)
                  + (if $row.transport == "stdio" then
                      (if ($c.command // "") != $row.command then ["codex\t\($row.name): codex command \($c.command // "absent") != \($row.command)"] else [] end)
                      + (if ($c.args // []) != ($row.args // []) then ["codex\t\($row.name): codex args \($c.args // [])"] else [] end)
                      + ((($c.env_vars // []) | sort) as $have
                         | (($row.envKeys // []) | sort) as $want
                         | if $have != $want then ["codex\t\($row.name): codex env_vars \($have) != \($want)"] else [] end)
                    else
                      (if ($c.url // "") != $row.url then ["codex\t\($row.name): codex url \($c.url // "absent")"] else [] end)
                      + (if ($c.bearer_token_env_var // null) != ($row.codex.bearerEnvVar // null) then ["codex\t\($row.name): codex bearer_token_env_var \($c.bearer_token_env_var // "absent")"] else [] end)
                      + (if ($c.env_http_headers // null) != ($row.codex.headerEnv // null) then ["codex\t\($row.name): codex env_http_headers drift"] else [] end)
                    end)
               end)
          )
      ]
    | flatten
    + (($cl | keys) - [$rows[] | select((.clients // ["claude", "codex"]) | index("claude")) | .name] | map("claude\t\(.): EXTRA in claude (not in manifest)"))
    + (($cx | keys) - [$rows[] | select((.clients // ["claude", "codex"]) | index("codex")) | .name] | map("codex\t\(.): EXTRA in codex (not in manifest)"))
    | .[]
  '';
  # Subset drift for projection registries (claude-shaped JSON: vscode servers
  # map, maghz .mcp.json). Registered rows naming a fleet row must honor its
  # contract; commands may spell the launcher basename; unknown rows are INFO.
  subsetClaudeJq = pkgs.writeText "mcp-drift-subset-claude.jq" ''
    ($fleet[0]) as $rows
    | (INDEX($rows[]; .name)) as $byName
    | ($reg[0] // {}) as $r
    | [
        $r | to_entries[]
        | .key as $n
        | .value as $c
        | ($byName[$n]) as $row
        | if $row == null then ["INFO \($n): local-only (not a manifest row)"]
          elif $row.transport == "stdio" then
            (if (($c.command // "") != $row.command) and (($c.command // "") != ($row.command | split("/") | last)) then ["\($n): command \($c.command // "absent") != \($row.command | split("/") | last)"] else [] end)
            + (if ($c.args // []) != ($row.args // []) then ["\($n): args \($c.args // [])"] else [] end)
            # Projections pass env explicitly (no ambient session env), so the
            # expectation is envKeys, never the claudeEnvNames mirror override.
            + ((($c.env // {}) | keys | sort) as $have
               | (($row.envKeys // []) | sort) as $want
               | if $have != $want then ["\($n): env names \($have) != \($want)"] else [] end)
          else
            (if ($c.url // "") != $row.url then ["\($n): url \($c.url // "absent")"] else [] end)
            + ((($c.headers // {}) | keys | sort) as $have
               | (($row.headerNames // []) | sort) as $want
               | if $have != $want then ["\($n): header names \($have) != \($want)"] else [] end)
          end
      ]
    | flatten | .[]
  '';
  # Subset drift for codex-shaped projections (maghz .codex/config.toml):
  # timeouts are host-local rows there, so only identity fields compare.
  subsetCodexJq = pkgs.writeText "mcp-drift-subset-codex.jq" ''
    ($fleet[0]) as $rows
    | (INDEX($rows[]; .name)) as $byName
    | ($reg[0] // {}) as $r
    | [
        $r | to_entries[]
        | .key as $n
        | .value as $c
        | ($byName[$n]) as $row
        | if $row == null then ["INFO \($n): local-only (not a manifest row)"]
          elif $row.transport == "stdio" then
            (if (($c.command // "") != $row.command) and (($c.command // "") != ($row.command | split("/") | last)) then ["\($n): command \($c.command // "absent") != \($row.command | split("/") | last)"] else [] end)
            + (if ($c.args // []) != ($row.args // []) then ["\($n): args \($c.args // [])"] else [] end)
            + ((($c.env_vars // []) | sort) as $have
               | (($row.envKeys // []) | sort) as $want
               | if $have != $want then ["\($n): env_vars \($have) != \($want)"] else [] end)
          else
            (if ($c.url // "") != $row.url then ["\($n): url \($c.url // "absent")"] else [] end)
            + (if ($c.bearer_token_env_var // null) != ($row.codex.bearerEnvVar // null) then ["\($n): bearer_token_env_var \($c.bearer_token_env_var // "absent") != \($row.codex.bearerEnvVar // "absent")"] else [] end)
            + (if ($c.env_http_headers // null) != ($row.codex.headerEnv // null) then ["\($n): env_http_headers drift"] else [] end)
          end
      ]
    | flatten | .[]
  '';
  # Desired-registration generator: one program per client shape, all reading
  # the same fleet rows — the "one generator" behind the five-way drift.
  generateClaudeJq = pkgs.writeText "mcp-generate-claude.jq" ''
    {
      mcpServers: ([
        .[]
        | select((.clients // ["claude", "codex"]) | index("claude"))
        | select((.assertLevel // "full") == "full")
        | {
            key: .name,
            value: (
              if .transport == "stdio" then
                {type: "stdio", command, args: (.args // []),
                 env: ((.claudeEnvNames // .envKeys // []) | map({key: ., value: ""}) | from_entries)}
              else
                {type: "http", url,
                 headers: ((.headerNames // []) | map({key: ., value: ""}) | from_entries)}
              end)
          }
      ] | from_entries)
    }
  '';
  generateCodexJq = pkgs.writeText "mcp-generate-codex.jq" ''
    .[]
    | select((.clients // ["claude", "codex"]) | index("codex"))
    | "[mcp_servers.\(.name)]"
      + (if .transport == "stdio" then
           "\ncommand = \(.command | tojson)"
           + (if (.args // []) != [] then "\nargs = \(.args | tojson)" else "" end)
           + (if (.envKeys // []) != [] then "\nenv_vars = \(.envKeys | tojson)" else "" end)
         else
           "\nurl = \(.url | tojson)"
           + (if .codex.bearerEnvVar != null then "\nbearer_token_env_var = \(.codex.bearerEnvVar | tojson)" else "" end)
           + (if .codex.headerEnv != null then "\nenv_http_headers = { \(.codex.headerEnv | to_entries | map("\(.key | tojson) = \(.value | tojson)") | join(", ")) }" else "" end)
         end)
      + (if (.codex.required // false) then "\nrequired = true" else "" end)
      + "\nstartup_timeout_sec = \(.codex.startupTimeoutSec)"
      + "\ntool_timeout_sec = \(.codex.toolTimeoutSec)"
      + "\n"
  '';
  generateVscodeJq = pkgs.writeText "mcp-generate-vscode.jq" ''
    {
      servers: ([
        .[]
        | select((.clients // ["claude", "codex"]) | index("claude"))
        | select((.assertLevel // "full") == "full")
        | {
            key: .name,
            value: (
              if .transport == "stdio" then
                {type: "stdio", command, args: (.args // []),
                 env: ((.envKeys // []) | map({key: ., value: "''${env:\(.)}"}) | from_entries)}
              else
                {type: "http", url,
                 headers: (
                   (if .codex.bearerEnvVar != null then {Authorization: "Bearer ''${env:\(.codex.bearerEnvVar)}"} else {} end)
                   + ((.codex.headerEnv // {}) | with_entries(.value = "''${env:\(.value)}")))}
              end)
          }
      ] | from_entries)
    }
  '';
  forgeMcp = pkgs.writeShellApplication {
    name = "forge-mcp";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.jq pkgs.yq-go pkgs.findutils pkgs.gawk pkgs.gnugrep];
    text = ''
      fleet='${fleetJson}'
      receipt_log="''${FORGE_MCP_RECEIPT_LOG:-$HOME/Library/Logs/forge-mcp.receipts.log}"
      maghz_root="''${FORGE_MAGHZ_ROOT:-$HOME/Documents/99.Github/Maghz}"
      vscode_mcp="$HOME/Library/Application Support/Code/User/mcp.json"
      usage() {
        echo "usage: forge-mcp outdated [--notify] [--json] | doctor [--network] [--json] | drift [--json]" >&2
        echo "       forge-mcp generate <claude|codex|vscode> | roots [--json] | snoop SERVER [-- ARGS...]" >&2
        exit 64
      }
      verb="''${1:-}"; shift || true

      iso_now() { TZ=UTC0 printf '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"; }
      receipt() { # $1=verb $2=result $3=detail
        local ts
        ts="$(iso_now)"
        mkdir -p "$(dirname "$receipt_log")"
        printf 'ts=%s\towner=forge-mcp\tverb=%s\tresult=%s\tdetail=%s\n' "$ts" "$1" "$2" "$3" >>"$receipt_log"
      }

      cmd_outdated() {
        notify=0 as_json=0
        for a in "$@"; do
          case "$a" in
            --notify) notify=1 ;;
            --json) as_json=1 ;;
            *) usage ;;
          esac
        done
        rc=0 rows=""
        while IFS="|" read -r pkg version; do
          if latest="$(curl -fsS --max-time 20 "https://registry.npmjs.org/$(jq -rn --arg p "$pkg" '$p|@uri')/latest" | jq -er .version)"; then
            if [ "$latest" != "$version" ]; then
              rows="$rows"$'\n'"OUTDATED"$'\t'"$pkg"$'\t'"$version"$'\t'"$latest"; rc=1
            else
              rows="$rows"$'\n'"current"$'\t'"$pkg"$'\t'"$version"$'\t'"$latest"
            fi
          else
            # Registry/network failure is not drift: report, never notify.
            rows="$rows"$'\n'"unknown"$'\t'"$pkg"$'\t'"$version"$'\t'"-"
          fi
        done < <(printf '%s\n' '${pins}')
        rows="''${rows#?}"
        n="$(printf '%s\n' "$rows" | grep -c $'^OUTDATED\t' || true)"
        if [ "$as_json" = 1 ]; then
          jq -Rcs --arg ts "$(iso_now)" --arg rc "$rc" '{
            schema: "forge-mcp/v1", ts: $ts, verb: "outdated",
            result: (if $rc == "0" then "ok" else "outdated" end),
            rows: (split("\n") | map(select(length > 0) | split("\t")
                   | {state: .[0], pkg: .[1], pin_current: .[2], latest: .[3]}))
          }' <<<"$rows"
        else
          printf '%s\n' "$rows" | while IFS=$'\t' read -r s p v l; do
            printf '%-9s %s pinned=%s latest=%s\n' "$s" "$p" "$v" "$l"
          done
        fi
        if [ "$notify" = 1 ] && [ "$rc" = 1 ]; then
          /usr/bin/osascript -e "display notification \"$n MCP pin(s) behind npm latest - run forge-mcp outdated\" with title \"Forge MCP pins\"" || true
        fi
        receipt outdated "$([ "$rc" = 0 ] && echo ok || echo outdated)" "outdated=$n"
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
          '[.name, .probe, .transport, (.codex.startupTimeoutSec // 20 | tostring)] | join("")' <<<"$row")
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

      # Named probe families: launcher rows declaring `doctor` get local checks
      # beyond initialize — the Forge launcher name IS the probe row.
      family_rows() { # $1=outfile
        local out="$1"
        while IFS= read -r row; do
          local name label port token
          name="$(jq -r '.name' <<<"$row")"
          label="$(jq -r '.doctor.launchdLabel // empty' <<<"$row")"
          port="$(jq -r '.doctor.port // empty' <<<"$row")"
          token="$(jq -r '.doctor.tokenFile // empty' <<<"$row")"
          if [ -n "$label" ]; then
            if /bin/launchctl print "gui/$(id -u)/$label" >/dev/null 2>&1; then
              pid="$(/bin/launchctl print "gui/$(id -u)/$label" 2>/dev/null | awk '/^\s*pid = /{print $3; exit}')"
              if [ -n "''${pid:-}" ]; then
                printf 'OK\t%s/launchd\t%s running pid=%s\n' "$name" "$label" "$pid" >>"$out"
              else
                printf 'FAIL\t%s/launchd\t%s loaded but not running\n' "$name" "$label" >>"$out"
              fi
            else
              printf 'FAIL\t%s/launchd\t%s absent from gui domain\n' "$name" "$label" >>"$out"
            fi
          fi
          if [ -n "$port" ]; then
            if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
              exec 3>&- 3<&- || true
              printf 'OK\t%s/port\tloopback %s bound\n' "$name" "$port" >>"$out"
            else
              printf 'FAIL\t%s/port\tloopback %s not listening\n' "$name" "$port" >>"$out"
            fi
          fi
          if [ -n "$token" ]; then
            if [ -s "$token" ]; then
              printf 'OK\t%s/token\tcustody file present\n' "$name" >>"$out"
            else
              printf 'FAIL\t%s/token\tcustody file absent or empty: %s\n' "$name" "$(basename "$token")" >>"$out"
            fi
          fi
          while IFS= read -r x; do
            [ -n "$x" ] || continue
            if command -v "$x" >/dev/null 2>&1; then
              printf 'OK\t%s/exec\t%s resolves\n' "$name" "$x" >>"$out"
            else
              printf 'FAIL\t%s/exec\t%s absent from PATH\n' "$name" "$x" >>"$out"
            fi
          done < <(jq -r '(.doctor.execs // [])[]' <<<"$row")
        done < <(jq -c '.[] | select(.doctor)' "$fleet")
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
        family_rows "$tmp/families"
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
          [ ! -f "$tmp/families" ] || cat "$tmp/families"
        } >"$rows"
        # Direct file grep: grep -q on the read end of a pipe SIGPIPEs the
        # writer under pipefail, and the negation would swallow real FAILs.
        rc=0
        ! grep -q $'^FAIL\t' "$rows" || rc=1
        if [ "$as_json" = 1 ]; then
          jq -Rcs --arg ts "$(iso_now)" --arg rc "$rc" '{
            schema: "forge-mcp/v1", ts: $ts, verb: "doctor",
            result: (if $rc == "0" then "ok" else "fail" end),
            rows: (split("\n") | map(select(length > 0) | split("\t")
                   | {status: .[0], name: .[1], detail: .[2]}))
          }' <"$rows"
        else
          while IFS=$'\t' read -r s n d; do
            printf '[%-4s] %-24s %s\n' "$s" "$n" "$d"
          done <"$rows"
        fi
        receipt doctor "$([ "$rc" = 0 ] && echo ok || echo fail)" "fails=$(grep -c $'^FAIL\t' "$rows" || true)"
        exit "$rc"
      }

      # Five-way registration drift: the manifest is the owner; every registry
      # is validated as a full mirror (claude, codex) or a declared projection
      # subset (vscode, maghz-claude, maghz-codex). Report-only, never mutates.
      cmd_drift() {
        as_json=0
        for a in "$@"; do
          case "$a" in
            --json) as_json=1 ;;
            *) usage ;;
          esac
        done
        tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
        # registry rows: name|class|present|clean|findings-file
        : >"$tmp/registries"

        # An unreadable/unparseable client config is total drift, not a crash.
        claude_json="$(jq '.mcpServers // {}' "$HOME/.claude.json" 2>/dev/null)" \
          || { echo "drift: cannot read mcpServers from ~/.claude.json"; exit 1; }
        codex_json="$(yq -p toml -o json '.mcp_servers // {}' "$HOME/.codex/config.toml" 2>/dev/null)" \
          || { echo "drift: cannot read mcp_servers from ~/.codex/config.toml"; exit 1; }
        jq -rn \
          --slurpfile fleet "$fleet" \
          --slurpfile claude <(printf '%s' "$claude_json") \
          --slurpfile codex <(printf '%s' "$codex_json") \
          -f '${driftJq}' >"$tmp/full" || true
        grep $'^claude\t' "$tmp/full" | cut -f2- >"$tmp/claude.f" || true
        grep $'^codex\t' "$tmp/full" | cut -f2- >"$tmp/codex.f" || true
        printf 'claude|full|1|%s|%s\n' "$([ -s "$tmp/claude.f" ] && echo 0 || echo 1)" "$tmp/claude.f" >>"$tmp/registries"
        printf 'codex|full|1|%s|%s\n' "$([ -s "$tmp/codex.f" ] && echo 0 || echo 1)" "$tmp/codex.f" >>"$tmp/registries"

        subset_lane() { # $1=registry-name $2=json-map $3=jq-program
          local name="$1" json="$2" prog="$3" f="$tmp/$1.f"
          jq -rn --slurpfile fleet "$fleet" --slurpfile reg <(printf '%s' "$json") -f "$prog" >"$f" || true
          local drift_lines
          drift_lines="$(grep -cv '^INFO ' "$f" || true)"
          printf '%s|subset|1|%s|%s\n' "$name" "$([ "$drift_lines" = 0 ] && echo 1 || echo 0)" "$f" >>"$tmp/registries"
        }
        if [ -f "$vscode_mcp" ]; then
          if v_json="$(jq '.servers // {}' "$vscode_mcp" 2>/dev/null)"; then
            subset_lane vscode "$v_json" '${subsetClaudeJq}'
          else
            printf 'vscode|subset|1|0|%s\n' /dev/null >>"$tmp/registries"
          fi
        else
          printf 'vscode|subset|0|1|%s\n' /dev/null >>"$tmp/registries"
        fi
        if [ -f "$maghz_root/.mcp.json" ]; then
          if m_json="$(jq '.mcpServers // {}' "$maghz_root/.mcp.json" 2>/dev/null)"; then
            subset_lane maghz-claude "$m_json" '${subsetClaudeJq}'
          else
            printf 'maghz-claude|subset|1|0|%s\n' /dev/null >>"$tmp/registries"
          fi
        else
          printf 'maghz-claude|subset|0|1|%s\n' /dev/null >>"$tmp/registries"
        fi
        if [ -f "$maghz_root/.codex/config.toml" ]; then
          if mc_json="$(yq -p toml -o json '.mcp_servers // {}' "$maghz_root/.codex/config.toml" 2>/dev/null)"; then
            subset_lane maghz-codex "$mc_json" '${subsetCodexJq}'
          else
            printf 'maghz-codex|subset|1|0|%s\n' /dev/null >>"$tmp/registries"
          fi
        else
          printf 'maghz-codex|subset|0|1|%s\n' /dev/null >>"$tmp/registries"
        fi

        rc=0
        while IFS='|' read -r _ _ present clean _; do
          [ "$present" = 0 ] || [ "$clean" = 1 ] || rc=1
        done <"$tmp/registries"

        if [ "$as_json" = 1 ]; then
          {
            while IFS='|' read -r name class present clean f; do
              jq -Rcs --arg name "$name" --arg class "$class" --arg present "$present" --arg clean "$clean" '{
                registry: $name, class: $class,
                present: ($present == "1"), clean: ($clean == "1"),
                findings: (split("\n") | map(select(length > 0)))
              }' <"$f"
            done <"$tmp/registries"
          } | jq -cs --arg ts "$(iso_now)" --arg rc "$rc" '{
            schema: "forge-mcp/v1", ts: $ts, verb: "drift",
            result: (if $rc == "0" then "clean" else "drift" end),
            registries: .
          }'
        else
          while IFS='|' read -r name class present clean f; do
            if [ "$present" = 0 ]; then
              printf 'drift %-13s (%s): registry absent, skipped\n' "$name" "$class"
            elif [ "$clean" = 1 ]; then
              printf 'drift %-13s (%s): clean\n' "$name" "$class"
              grep '^INFO ' "$f" 2>/dev/null | while IFS= read -r l; do printf '  %s\n' "$l"; done || true
            else
              printf 'drift %-13s (%s): DRIFT\n' "$name" "$class"
              while IFS= read -r l; do printf '  %s\n' "$l"; done <"$f"
            fi
          done <"$tmp/registries"
        fi
        receipt drift "$([ "$rc" = 0 ] && echo clean || echo drift)" "registries=5"
        exit "$rc"
      }

      # Desired-registration generator: emits the manifest-derived fragment for
      # one client shape; values are env NAMES or empty strings, never secrets.
      cmd_generate() {
        case "''${1:-}" in
          claude) jq -f '${generateClaudeJq}' "$fleet" ;;
          codex) jq -rf '${generateCodexJq}' "$fleet" ;;
          vscode) jq -f '${generateVscodeJq}' "$fleet" ;;
          *) usage ;;
        esac
      }

      # Agent-root observability: runtime corpus facts (counts + sizes) for the
      # CA-9 retention board. Read-only; class names are the retention rows.
      cmd_roots() {
        as_json=0; [ "''${1:-}" != "--json" ] || as_json=1
        scan() { # $1=root $2=class $3=path
          local files kb
          [ -e "$3" ] || return 0
          files="$(find "$3" -type f 2>/dev/null | wc -l | tr -d ' ')"
          kb="$(du -sk "$3" 2>/dev/null | cut -f1)"
          printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "''${3/#"$HOME"/\~}" "$files" "''${kb:-0}"
        }
        rows="$(
          scan claude transcripts "$HOME/.claude/projects"
          scan claude file-history "$HOME/.claude/file-history"
          scan claude session-env "$HOME/.claude/session-env"
          scan claude tasks "$HOME/.claude/tasks"
          scan claude backups "$HOME/.claude/backups"
          scan codex sessions "$HOME/.codex/sessions"
          scan codex archives "$HOME/.codex/archived_sessions"
          scan codex tmp-staging "$HOME/.codex/.tmp"
          scan codex tmp "$HOME/.codex/tmp"
          scan codex attachments "$HOME/.codex/attachments"
          scan forge-mcp launcher-cache "''${XDG_CACHE_HOME:-$HOME/.cache}/forge-mcp"
          scan forge-mcp snoop-logs "${snoopPolicy.logDir}"
        )"
        if [ "$as_json" = 1 ]; then
          jq -Rcs --arg ts "$(iso_now)" '{
            schema: "forge-mcp/v1", ts: $ts, verb: "roots", result: "ok",
            rows: (split("\n") | map(select(length > 0) | split("\t")
                   | {root: .[0], class: .[1], path: .[2], files: (.[3] | tonumber), kb: (.[4] | tonumber)}))
          }' <<<"$rows"
        else
          printf '%-10s %-14s %-42s %10s %12s\n' ROOT CLASS PATH FILES KB
          printf '%s\n' "$rows" | while IFS=$'\t' read -r r c p f k; do
            printf '%-10s %-14s %-42s %10s %12s\n' "$r" "$c" "$p" "$f" "$k"
          done
        fi
        receipt roots ok "rows=$(printf '%s\n' "$rows" | grep -c . || true)"
      }

      # Gated traffic capture: opt-in env required, frame metadata only
      # (direction, kind, method, id, bytes — params/results never persist),
      # logs age out at ${toString snoopPolicy.retentionDays}d. Capture without
      # the policy gate is unreachable.
      cmd_snoop() {
        server="''${1:-}"; shift || true
        [ "''${1:-}" != "--" ] || shift
        [ -n "$server" ] || usage
        if [ "''${${snoopPolicy.optInEnv}:-}" != "1" ]; then
          echo "forge-mcp snoop: debug capture is opt-in; run with ${snoopPolicy.optInEnv}=1 (redaction=${snoopPolicy.redaction}, retention=${toString snoopPolicy.retentionDays}d)" >&2
          exit 78
        fi
        row="$(jq -c --arg n "$server" '.[] | select(.name == $n and .transport == "stdio")' "$fleet")"
        [ -n "$row" ] || { echo "forge-mcp snoop: no stdio manifest row named $server" >&2; exit 64; }
        logdir="${snoopPolicy.logDir}"
        mkdir -p "$logdir"
        find "$logdir" -type f -mtime +${toString snoopPolicy.retentionDays} -delete 2>/dev/null || true
        log="$logdir/$server.$(date -u +%Y%m%dT%H%M%SZ).jsonl"
        cmdpath="$(jq -r '.command' <<<"$row")"
        mapfile -t argv < <(jq -r '(.args // [])[]' <<<"$row")
        meta() { # $1=direction
          jq -c --unbuffered --arg dir "$1" '{
            ts: (now | todate), dir: $dir,
            kind: (if .method then "request" elif .result then "result" elif .error then "error" else "other" end),
            method: (.method // null), id: (.id // null),
            bytes: (tostring | length)
          }' 2>/dev/null >>"$log" || true
        }
        echo "forge-mcp snoop: $server -> $log (${snoopPolicy.redaction})" >&2
        exec "$cmdpath" ''${argv[0]+"''${argv[@]}"} "$@" \
          < <(tee >(meta client) </dev/stdin) \
          > >(tee >(meta server))
      }

      case "$verb" in
        outdated) cmd_outdated "$@" ;;
        doctor) cmd_doctor "$@" ;;
        drift) cmd_drift "$@" ;;
        generate) cmd_generate "$@" ;;
        roots) cmd_roots "$@" ;;
        snoop) cmd_snoop "$@" ;;
        *) usage ;;
      esac
    '';
  };

  # --- forge-agents: the CA-7 collector -------------------------------------
  # One data owner turns agent lanes, attention, and AI quota into one cached
  # fact set; the zjstatus top bar is the ONE surface rendering the cells.
  # Quota lanes: Codex from provider rate_limit snapshots in session rollouts;
  # Claude from local transcript/stats estimation (source-labeled). Failed
  # lanes preserve the previous value with stale=true and back off
  # exponentially. Projections: role-styled zjstatus pipe cells, workspace-
  # graph lane rows, policy-gated desktop notification whose click routes
  # back to the raising pane via the `focus` verb.
  forgeAgents = pkgs.writeShellApplication {
    name = "forge-agents";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.findutils pkgs.gawk pkgs.gnugrep];
    text = ''
            state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/forge"
            cache="$state_root/agent-state.json"
            meta="$state_root/agent-collect.meta.json"
            feed="$state_root/agent-attention.jsonl"
            lanes_out="''${XDG_CACHE_HOME:-$HOME/.cache}/forge/agent-lanes.json"
            receipt_log="''${FORGE_AGENTS_RECEIPT_LOG:-$HOME/Library/Logs/forge-agents.receipts.log}"
            usage() { echo "usage: forge-agents collect | status [--json] | focus" >&2; exit 64; }
            verb="''${1:-status}"; shift || true

            iso_now() { TZ=UTC0 printf '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"; }

            cmd_status() {
              if [ ! -f "$cache" ]; then
                echo "forge-agents: no cache yet; run forge-agents collect" >&2
                exit 1
              fi
              if [ "''${1:-}" = "--json" ]; then
                jq . "$cache"
              else
                jq -r '
                  "as-of      \(.ts)",
                  "lanes      running=\(.lanes.running) waiting=\(.lanes.waiting) needs_input=\(.attention.needs_input)",
                  (.lanes.rows[]? | "  pid=\(.pid) \(.agent) cpu=\(.cpu) tty=\(.tty) up=\(.etime)"),
                  "codex      5h=\(.quota.codex.primary_used_percent // "?")% 7d=\(.quota.codex.secondary_used_percent // "?")% stale=\(.quota.codex.stale) source=\(.quota.codex.source // "-")",
                  "claude     5h_tokens=\(.quota.claude.window_tokens // 0) 7d_tokens=\(.quota.claude.week_tokens // 0) stale=\(.quota.claude.stale) source=\(.quota.claude.source // "-")"
                ' "$cache"
              fi
            }

            cmd_collect() {
              mkdir -p "$state_root" "$(dirname "$lanes_out")"
              now="$EPOCHSECONDS"
              ts="$(iso_now)"
              prev="$(cat "$cache" 2>/dev/null || echo '{}')"
              m="$(cat "$meta" 2>/dev/null || echo '{}')"

              # Lane backoff: a failing provider lane is skipped for min(60*2^n, 3600)s.
              should_run() { # $1=lane
                jq -e --arg l "$1" --argjson now "$now" '
                  (.lanes[$l] // {failures: 0, last_attempt: 0}) as $s
                  | ($s.failures == 0) or ($now - $s.last_attempt) >= ([60 * pow(2; $s.failures), 3600] | min)
                ' <<<"$m" >/dev/null
              }

              # --- agent lanes: process facts -----------------------------------
              lanes_rows="$(/bin/ps -axo pid=,pcpu=,tt=,etime=,args= | awk '
                {
                  n = split($5, parts, "/"); base = parts[n]
                  if (base == "claude" || base == "codex")
                    printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, base
                }' | jq -Rcs 'split("\n") | map(select(length > 0) | split("\t")
                  | {pid: (.[0] | tonumber), cpu: (.[1] | tonumber), tty: .[2], etime: .[3], agent: .[4],
                     state: (if (.[1] | tonumber) >= 5 then "running" else "waiting" end)})')"

              # --- attention: hook-feed fold joined against live process facts.
              # A session needs input only when its latest event is Notification
              # within the window AND its recorded tty still hosts an idle claude
              # lane; one row per tty so stacked tabs never inflate the count, and
              # the newest row keeps its identity so `focus` can route the click --
              att_cut="$(date -u -d '-60 minutes' +%Y-%m-%dT%H:%M:%SZ)"
              att="$(tail -n 500 "$feed" 2>/dev/null | jq -cs --arg cut "$att_cut" --argjson lanes "$lanes_rows" '
                def pty: sub("^tty"; "");
                ([$lanes[] | select(.agent == "claude" and .state == "waiting") | .tty | pty] | unique) as $idle
                | [group_by(.session_id)[] | max_by(.ts)
                   | select(.event == "Notification" and .ts >= $cut
                            and ((.tty // "") as $t | $t != "" and ($idle | index($t | pty))))]
                | unique_by(.tty)
                | {needs_input: length, latest: (max_by(.ts) // null)}' 2>/dev/null \
                || echo '{"needs_input": 0, "latest": null}')"
              needs="$(jq -r '.needs_input' <<<"$att")"

              # --- quota: codex provider snapshots --------------------------------
              cx_prev="$(jq -c '.quota.codex // {}' <<<"$prev")"
              cx="$cx_prev"; cx_ok=1
              if should_run codex; then
                cx_ok=0
                while IFS= read -r f; do
                  rl="$(jq -c 'select(.payload.rate_limits.primary) | .payload.rate_limits' "$f" 2>/dev/null | tail -1)"
                  if [ -n "$rl" ]; then
                    cx="$(jq -c --arg ts "$ts" '{
                      provider: "codex", source: "provider", as_of: $ts, stale: false, error: null,
                      primary_used_percent: .primary.used_percent, primary_window_min: .primary.window_minutes,
                      primary_resets_at: .primary.resets_at,
                      secondary_used_percent: .secondary.used_percent, secondary_window_min: .secondary.window_minutes,
                      secondary_resets_at: .secondary.resets_at
                    }' <<<"$rl")"
                    cx_ok=1
                    break
                  fi
                done < <(find "$HOME/.codex/sessions" -type f -name '*.jsonl' -newermt '-7 days' -printf '%T@ %p\n' 2>/dev/null \
                  | sort -rn | head -20 | cut -d' ' -f2-)
                if [ "$cx_ok" = 0 ]; then
                  cx="$(jq -c '. + {stale: true, error: "no rate_limit snapshot within 7d"}' <<<"$cx_prev")"
                fi
              fi

              # --- quota: claude local estimation ---------------------------------
              cl_prev="$(jq -c '.quota.claude // {}' <<<"$prev")"
              cl="$cl_prev"; cl_ok=1
              if should_run claude; then
                cl_ok=0
                cutoff="$(date -u -d '-5 hours' +%Y-%m-%dT%H:%M:%SZ)"
                win_tok="$(
                  find "$HOME/.claude/projects" -type f -name '*.jsonl' -newermt '-5 hours' -print0 2>/dev/null \
                    | while IFS= read -r -d "" f; do tail -n 2000 "$f" 2>/dev/null | grep '"usage"' || true; done \
                    | jq -n --arg c "$cutoff" \
                      '[inputs | select(type == "object" and .message.usage and ((.timestamp // "") >= $c))
                        | .message.usage | ((.input_tokens // 0) + (.output_tokens // 0))] | add // 0' 2>/dev/null
                )" || win_tok=""
                week_tok="$(jq --arg d "$(date -u -d '-7 days' +%Y-%m-%d)" \
                  '[.dailyModelTokens[]? | select(.date >= $d) | .tokensByModel | add] | add // 0' \
                  "$HOME/.claude/stats-cache.json" 2>/dev/null)" || week_tok=""
                week_asof="$(jq -r '.lastComputedDate // "-"' "$HOME/.claude/stats-cache.json" 2>/dev/null || echo -)"
                if [ -n "$win_tok" ]; then
                  cl="$(jq -cn --arg ts "$ts" --argjson w "$win_tok" --argjson wk "''${week_tok:-0}" --arg wa "$week_asof" '{
                    provider: "claude", source: "local-estimate", as_of: $ts, stale: false, error: null,
                    window_min: 300, window_tokens: $w, burn_tokens_per_hour: (($w / 5) | floor),
                    week_tokens: $wk, week_as_of: $wa
                  }')"
                  cl_ok=1
                else
                  cl="$(jq -c '. + {stale: true, error: "transcript scan failed"}' <<<"$cl_prev")"
                fi
              fi

              # --- cache assembly --------------------------------------------------
              tmp_cache="$cache.tmp.$$"
              jq -cn --arg ts "$ts" --argjson lanes "$lanes_rows" --argjson att "$att" \
                --argjson cx "$cx" --argjson cl "$cl" '{
                schema: "forge-agents/v1", ts: $ts,
                lanes: {
                  rows: $lanes,
                  running: ([$lanes[] | select(.state == "running")] | length),
                  waiting: ([$lanes[] | select(.state == "waiting")] | length)
                },
                attention: $att,
                quota: {codex: $cx, claude: $cl}
              }' >"$tmp_cache"
              mv "$tmp_cache" "$cache"

              # --- projections ------------------------------------------------------
              # The zjstatus top bar is the ONE render surface; the collector owns
              # role->palette styling (build-time hexes from the theme owner) and
              # ships fully formatted payloads the bar renders verbatim (dynamic).
              run_n="$(jq -r '.lanes.running' "$cache")"
              wait_n="$(jq -r '.lanes.waiting' "$cache")"
              agents_text="AI ''${run_n}▸ ''${wait_n}⋯"
              [ "''${needs:-0}" = 0 ] || agents_text="$agents_text ''${needs}✋"
              cx_p="$(jq -r '.quota.codex.primary_used_percent // empty' "$cache")"
              cx_s="$(jq -r '.quota.codex.secondary_used_percent // empty' "$cache")"
              cl_w="$(jq -r '.quota.claude.window_tokens // empty' "$cache")"
              quota_text=""
              if [ -n "$cx_p" ]; then quota_text="CX ''${cx_p%.*}%·''${cx_s%.*}%"; fi
              if [ -n "$cl_w" ]; then
                cl_h="$(jq -rn --argjson t "$cl_w" 'if $t >= 1000000 then "\(($t / 100000 | floor) / 10)M" elif $t >= 1000 then "\(($t / 1000 | floor))K" else "\($t)" end')"
                quota_text="''${quota_text:+$quota_text }CL $cl_h"
              fi
              [ -n "$quota_text" ] || quota_text="quota -"

              # Cell state colors: agents muted when idle, success while lanes run,
              # attention on needs_input; quota escalates on the codex 5h window.
              agents_fg="${roles.text.muted.hex}"
              [ "$run_n" = 0 ] || agents_fg="${roles.state.success.hex}"
              [ "''${needs:-0}" = 0 ] || agents_fg="${roles.state.attention.hex}"
              quota_fg="${roles.text.muted.hex}"
              if [ -n "$cx_p" ]; then
                p="''${cx_p%.*}"
                if [ "$p" -ge 90 ]; then quota_fg="${roles.state.danger.hex}"
                elif [ "$p" -ge 70 ]; then quota_fg="${roles.state.warning.hex}"; fi
              fi
              mk_cell() { # $1=fg $2=attrs("" or ",bold") $3=text -> raised chip + surface gap (the bar plane)
                printf '#[bg=${roles.surface.raised.hex},fg=%s%s] %s #[bg=${roles.surface.surface.hex}] ' "$1" "$2" "$3"
              }
              agents_cell="$(mk_cell "$agents_fg" ",bold" "$agents_text")"
              quota_cell="$(mk_cell "$quota_fg" "" "$quota_text")"

              # Workspace-graph lane rows: the forge-zellij agent-lane arm reads this.
              jq -c '[.lanes.rows[] | {lane: "\(.agent)-\(.pid)", status: .state, pane_id: ""}]' \
                "$cache" >"$lanes_out.tmp.$$"
              mv "$lanes_out.tmp.$$" "$lanes_out"

              # zjstatus pipe cells into every live session; a dead server is benign.
              while IFS= read -r s; do
                [ -n "$s" ] || continue
                ${profileBin}/zellij --session "$s" pipe "zjstatus::pipe::pipe_agents::$agents_cell" 2>/dev/null || true
                ${profileBin}/zellij --session "$s" pipe "zjstatus::pipe::pipe_quota::$quota_cell" 2>/dev/null || true
              done < <(${profileBin}/zellij list-sessions -ns 2>/dev/null || true)

              # Policy-gated desktop notification on a needs_input rise; the click
              # runs `forge-agents focus` (osascript notifications route clicks to
              # Script Editor, so posting goes through terminal-notifier instead).
              prev_needs="$(jq -r '.attention.needs_input // 0' <<<"$prev")"
              last_notify="$(jq -r '.last_notify // 0' <<<"$m")"
              notified=0
              if ${lib.boolToString notifyPolicy.needsInput} \
                && [ "''${needs:-0}" -gt "''${prev_needs:-0}" ] \
                && [ $((now - last_notify)) -ge ${toString notifyPolicy.minIntervalSec} ]; then
                ${pkgs.terminal-notifier}/bin/terminal-notifier -title "Forge Agents" \
                  -message "''${needs} agent session(s) waiting for input" \
                  -group forge-agents -execute "${profileBin}/forge-agents focus" >/dev/null 2>&1 || true
                notified=1
              fi

              # --- meta + transition receipt ---------------------------------------
              jq -cn --argjson now "$now" --argjson m "$m" \
                --argjson cx_ok "$cx_ok" --argjson cl_ok "$cl_ok" --argjson notified "$notified" '
                ($m.lanes // {}) as $l
                | {
                    last_notify: (if $notified == 1 then $now else ($m.last_notify // 0) end),
                    lanes: {
                      codex: (if $cx_ok == 1 then {failures: 0, last_attempt: $now}
                              else {failures: ((($l.codex.failures // 0) + 1) | if . > 6 then 6 else . end), last_attempt: $now} end),
                      claude: (if $cl_ok == 1 then {failures: 0, last_attempt: $now}
                               else {failures: ((($l.claude.failures // 0) + 1) | if . > 6 then 6 else . end), last_attempt: $now} end)
                    }
                  }' >"$meta.tmp.$$"
              mv "$meta.tmp.$$" "$meta"

              # jq's // coerces false to the alternative; != false keeps a real false.
              summary="needs=''${needs:-0} run=$run_n cx_stale=$(jq -r '.quota.codex.stale != false' "$cache") cl_stale=$(jq -r '.quota.claude.stale != false' "$cache")"
              prev_summary="$(jq -r '"needs=\(.attention.needs_input // 0) run=\(.lanes.running // 0) cx_stale=\(.quota.codex.stale != false) cl_stale=\(.quota.claude.stale != false)"' <<<"$prev" 2>/dev/null || echo "")"
              if [ "$summary" != "$prev_summary" ] || [ "$notified" = 1 ]; then
                mkdir -p "$(dirname "$receipt_log")"
                printf 'ts=%s\towner=forge-agents\tverb=collect\tresult=ok\t%s\tnotified=%s\n' \
                  "$ts" "''${summary// /$'\t'}" "$notified" >>"$receipt_log"
              fi
            }

            # Click-routing: land the operator on the pane that raised attention.
            # Inner hop focuses the zellij pane; outer hop resolves the attached
            # client's pty to its hosting wezterm pane or Terminal tab and raises it.
            # Every run leaves a lane receipt: notification clicks execute headless,
            # so the receipt log is the only witness when routing goes sideways.
            focus_receipt() {
              mkdir -p "$(dirname "$receipt_log")"
              printf 'ts=%s\towner=forge-agents\tverb=focus\tlane=%s\ttty=%s\n' \
                "$(iso_now)" "$1" "''${tty:-.}" >>"$receipt_log" 2>/dev/null || true
            }
            cmd_focus() {
              row="$(jq -c '.attention.latest // empty' "$cache" 2>/dev/null || true)"
              [ -n "$row" ] || row="$(tail -n 500 "$feed" 2>/dev/null | jq -cs '
                [group_by(.session_id)[] | max_by(.ts) | select(.event == "Notification")]
                | max_by(.ts) // empty' 2>/dev/null || true)"
              zs="$(jq -r '.zellij_session // ""' <<<"$row" 2>/dev/null || true)"
              zp="$(jq -r '.zellij_pane // ""' <<<"$row" 2>/dev/null || true)"
              wp="$(jq -r '.wezterm_pane // ""' <<<"$row" 2>/dev/null || true)"
              tp="$(jq -r '.term // ""' <<<"$row" 2>/dev/null || true)"
              tty="$(jq -r '.tty // ""' <<<"$row" 2>/dev/null || true)"
              wezbin="/Applications/WezTerm.app/Contents/MacOS/wezterm"
              [ -x "$wezbin" ] || wezbin="$(command -v wezterm || true)"

              # Inner hop: focus the exact zellij pane, then chase the attached
              # client's pty (reattachment moves it, so the row's tty is advisory).
              live_sessions="$(${profileBin}/zellij list-sessions -ns 2>/dev/null || true)"
              if [ -n "$zs" ] && grep -qxF "$zs" <<<"$live_sessions"; then
                [ -z "$zp" ] || ${profileBin}/zellij --session "$zs" action focus-pane-id "$zp" 2>/dev/null || true
                ctty="$(/bin/ps -axo tty=,args= | awk -v s="$zs" \
                  '$1 != "??" && $0 ~ /zellij/ && $0 !~ /--server/ && index($0, s) {print $1; exit}' || true)"
                [ -z "$ctty" ] || tty="$ctty"
              fi

              # Outer hop: wezterm pane by pty, recorded wezterm pane, Terminal tab
              # by pty, then a bare app raise as the last resort.
              if [ -n "$wezbin" ] && [ -n "$tty" ]; then
                pane="$("$wezbin" cli list --format json 2>/dev/null \
                  | jq -r --arg t "/dev/$tty" '.[] | select(.tty_name == $t) | .pane_id' | head -n1 || true)"
                if [ -n "$pane" ]; then
                  "$wezbin" cli activate-pane --pane-id "$pane" 2>/dev/null || true
                  /usr/bin/open -a WezTerm 2>/dev/null || true
                  focus_receipt "wezterm-pty"
                  return 0
                fi
              fi
              if [ -n "$wp" ] && [ -n "$wezbin" ] && "$wezbin" cli activate-pane --pane-id "$wp" 2>/dev/null; then
                /usr/bin/open -a WezTerm 2>/dev/null || true
                focus_receipt "wezterm-pane"
                return 0
              fi
              if [ "$tp" = "Apple_Terminal" ] && [ -n "$tty" ]; then
                hit="$(/usr/bin/osascript 2>/dev/null <<OSA
      tell application "Terminal"
        repeat with w in windows
          repeat with t in tabs of w
            if (tty of t) is "/dev/$tty" then
              set selected of t to true
              set index of w to 1
              activate
              return "hit"
            end if
          end repeat
        end repeat
      end tell
      return ""
      OSA
                )" || hit=""
                if [ "$hit" = "hit" ]; then
                  focus_receipt "terminal-tab"
                  return 0
                fi
              fi
              # App-level fallback honors the recorded host app; a TCC-blocked
              # tab match still lands the operator on the right application.
              if [ "$tp" = "Apple_Terminal" ]; then
                /usr/bin/open -a Terminal 2>/dev/null || true
                focus_receipt "terminal-app"
              else
                /usr/bin/open -a WezTerm 2>/dev/null || true
                focus_receipt "wezterm-app"
              fi
            }

            case "$verb" in
              collect) cmd_collect ;;
              status) cmd_status "$@" ;;
              focus) cmd_focus ;;
              *) usage ;;
            esac
    '';
  };

  # Completion projections for the fleet/agent surface.
  mcpCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-mcp" ''
    #compdef forge-mcp
    _arguments \
      '1:verb:(outdated doctor drift generate roots snoop)' \
      '--notify[Notification Center on outdated pins]' \
      '--network[probe network-class rows]' \
      '--json[schema=forge-mcp/v1 receipt]'
  '';
  agentsCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-agents" ''
    #compdef forge-agents
    _arguments \
      '1:verb:(collect status focus)' \
      '--json[raw collector cache]'
  '';

  # Hidden-identity app bundle rows: Login Items & Extensions resolves each
  # agent's AssociatedBundleIdentifiers to a real name instead of the "/bin/sh"
  # basename home-manager's mutateConfig writes into ProgramArguments[0].
  bundleRows = {
    "forge-mcp-drift" = "Forge MCP Drift";
    "forge-agents" = "Forge Agents";
  };
  mkBundlePlist = ident: display: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key>
      <string>com.parametric-forge.${ident}</string>
      <key>CFBundleName</key>
      <string>${display}</string>
      <key>CFBundleDisplayName</key>
      <string>${display}</string>
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
in {
  home = {
    packages = launchers ++ [maghzPostgres rhinoRouter forgeMcp forgeAgents mcpCompletion agentsCompletion];

    file =
      lib.mapAttrs' (
        ident: display:
          lib.nameValuePair "Applications/${display}.app/Contents/Info.plist" {
            text = mkBundlePlist ident display;
          }
      )
      bundleRows;

    activation.registerForgeAgentApps = lib.hm.dag.entryAfter ["linkGeneration"] ''
      lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
      for app in ${lib.concatStringsSep " " (map (d: "\"$HOME/Applications/${d}.app\"") (lib.attrValues bundleRows))}; do
        if [ -d "$app" ] && [ -x "$lsregister" ]; then
          "$lsregister" -f "$app" || true
        fi
      done
    '';
  };

  launchd.agents = {
    # Weekly pin-drift banner: Notification Center only when a pin is outdated;
    # silent when current or offline (a registry failure never notifies).
    forge-mcp-outdated = {
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
    # Minute-cadence collector: cached facts for the bar cells; receipts land
    # only on state transitions so the log stays quiet.
    forge-agents = {
      enable = true;
      config = {
        Label = "com.parametric-forge.forge-agents";
        ProgramArguments = ["${forgeAgents}/bin/forge-agents" "collect"];
        StartInterval = 60;
        RunAtLoad = true;
        ProcessType = "Background";
        Nice = 10;
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-agents.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-agents.log";
        AssociatedBundleIdentifiers = ["com.parametric-forge.forge-agents"];
      };
    };
  };
}
