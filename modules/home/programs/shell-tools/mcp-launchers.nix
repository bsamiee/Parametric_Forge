# Title         : mcp-launchers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mcp-launchers.nix
# ----------------------------------------------------------------------------
# Data-plane owner: builds pinned pnpm launchers from mcp-fleet.nix rows and ships the MCP observability surface — `forge-mcp` emitting
# schema=forge-mcp/v1 receipts across outdated/doctor/drift/reconcile/generate/roots/snoop, the shared supervised-stdio lane binding each server
# subtree to client liveness, the Maghz postgres DSN launcher, and the Rhino router gate. Launcher code never touches providers or credentials.
{
  config,
  lib,
  pkgs,
  ...
}: let
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  stateHome = config.xdg.stateHome;
  # Shared owner: the dual-receipt emit fold (receipts.nix) that forge-mcp folds for its schema=forge-mcp/v1 receipt surface.
  receiptsFold = import ./receipts.nix;
  fleet = import ./mcp-fleet.nix {
    inherit profileBin;
    homeDir = config.home.homeDirectory;
    sshBin = "${pkgs.openssh}/bin/ssh";
  };
  launcherRows = builtins.filter (r: r ? launcher) fleet;
  fleetJson = pkgs.writeText "mcp-fleet.json" (builtins.toJSON fleet);
  # Shared supervised stdio lane: every launcher binds its server subtree to bidirectional protocol activity, so an abandoned client generation
  # expires under a bounded inactivity lease and converges through process-group reap even when obsolete writers retain stdin.
  superviseStdio = import ./supervise-stdio.nix;
  forgeSuperviseStdio = pkgs.writeShellApplication {
    name = "forge-supervise-stdio";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      if [ "''${1:-}" = "--idle-seconds" ]; then
        idle_seconds="''${2:-}"
        if [[ ! "$idle_seconds" =~ ^[1-9][0-9]*$ ]]; then
          printf 'forge-supervise-stdio: --idle-seconds requires a positive integer, got: %s\n' "''${idle_seconds:-<missing>}" >&2
          exit 64
        fi
        export FORGE_STDIO_IDLE_SECONDS="$idle_seconds"
        shift 2
      fi
      if [ "''${1:-}" = "--" ]; then
        shift
      fi
      if [ "$#" -eq 0 ]; then
        printf 'usage: forge-supervise-stdio [--idle-seconds N] [--] COMMAND [ARGS...]\n' >&2
        exit 64
      fi
      cmd="$1"
      shift
      ${superviseStdio ''"$cmd"''}
    '';
  };

  # Traffic-capture policy rows (annex-gated): capture is unreachable without the opt-in env, frames log metadata only, and files age out.
  snoopPolicy = {
    optInEnv = "FORGE_MCP_DEBUG";
    redaction = "frame-metadata-only"; # direction, method, id, kind, bytes — never params/results
    retentionDays = 7;
    logDir = "${stateHome}/forge-mcp-snoop";
  };
  mkLauncher = row: name:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [pkgs.coreutils pkgs.nodejs-bin_26 pkgs.pnpm_11];
      text = ''
        ${row.launcher.prelude or ""}prefix="''${XDG_CACHE_HOME:-$HOME/.cache}/forge-mcp/${row.launcher.pkg}/${row.launcher.version}"
        entry="$prefix/node_modules/.bin/${row.launcher.bin}"
        if [ ! -x "$entry" ]; then
          # Stage-then-rename: fleet clients spawn every server at once, so first installs race; each racer stages privately, the rename winner owns
          # the prefix, and losers discard their stage and exec the winner's tree.
          parent="$(dirname "$prefix")"
          mkdir -p "$parent"
          stage="$(mktemp -d "$parent/.stage.XXXXXX")"
          # Failure litter guard: an errexit death mid-install must not strand the stage, so every success path removes or promotes it first.
          trap 'rm -rf "$stage"' EXIT
          # --config rows pin XDG containment for launchd spawns without session env; prefer-offline lets exact pins cold-start from a warm store.
          pnpm add --dir "$stage" \
            --config.loglevel=error \
            --config.prefer-offline=true \
            --config.store-dir="''${XDG_DATA_HOME:-$HOME/.local/share}/pnpm/store" \
            --config.cache-dir="''${XDG_CACHE_HOME:-$HOME/.cache}/pnpm" \
            --config.state-dir="''${XDG_STATE_HOME:-$HOME/.local/state}/pnpm" \
            "${row.launcher.pkg}@${row.launcher.version}" >&2 || true
          # Success predicate is the staged bin, not pnpm's exit status: a node teardown crash after full materialization must not kill cold-start,
          # and a tree missing its bin must never be promoted to the prefix.
          if [ -x "$entry" ]; then
            rm -rf "$stage"
          elif [ -x "$stage/node_modules/.bin/${row.launcher.bin}" ]; then
            # mv first: a prefix a racer just promoted must never be deleted; only a still-corrupt prefix is cleared, then one retry.
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
        export FORGE_STDIO_IDLE_SECONDS=${toString (row.launcher.idleSeconds or (row.codex.toolTimeoutSec + 300))}
        ${superviseStdio ''"$entry"''}
      '';
    };
  launchers = lib.concatMap (row: map (mkLauncher row) row.launcher.names) launcherRows;
  # Maghz postgres DSN via MAGHZ_MCP__DATABASE_URI, launchd GUI replay fallback; loud exit 78 when unresolved so required-server failure is visible.
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
      export DATABASE_URI="$MAGHZ_MCP__DATABASE_URI" UV_PYTHON_DOWNLOADS=automatic
      ${superviseStdio ''uvx --python 3.13 postgres-mcp --access-mode=restricted''}
    '';
  };
  # Rhino's package manager owns the router install; version-globbing keeps client configs stable across McNeel package updates. Lifecycle gate: the
  # heavy vendor router spawns only while Rhino 9 WIP runs; otherwise a stdio shim serves one rhino_status tool (start Rhino, then reconnect). The
  # shared supervised lane ties the router subtree to client liveness through the stdin relay, so a dead, killed, or reconnecting client tears the
  # subtree down; no session exit strands a router, and the vendor binary exposes no idle-exit.
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
        # Host-liveness watchdog: Rhino exit TERMs this wrapper (never Rhino itself), so the supervised router generation reaps within a poll of
        # the app closing. The lstart identity pin makes the TERM target exact — a recycled PID mismatches and the watchdog exits instead.
        guard=$$
        guard_start="$(/bin/ps -o lstart= -p "$guard" 2>/dev/null || true)"
        (
          while /usr/bin/pgrep -qf "$rhino_bin"; do
            [ "$(/bin/ps -o lstart= -p "$guard" 2>/dev/null || true)" = "$guard_start" ] || exit 0
            sleep 3
          done
          [ "$(/bin/ps -o lstart= -p "$guard" 2>/dev/null || true)" = "$guard_start" ] && kill -TERM "$guard" 2>/dev/null || true
        ) &
        ${superviseStdio ''"$entry"''}
      fi

      # Rhino-down entry: any live vendor router is a stray from a dead generation. The liveness recheck pins the sweep to a still-down Rhino,
      # so a router another session just spawned against a freshly opened app is never collateral.
      /usr/bin/pgrep -qf "$rhino_bin" || /usr/bin/pkill -f "Rhino-MCP-Platform/.*/router/osx-arm64/rhino-mcp-router" 2>/dev/null || true

      # Thin responder: newline-delimited JSON-RPC over stdio at near-zero cost. Its blocking read carries a long idle lease directly, so retained
      # inherited pipe writers cannot strand an app-server generation and the Rhino-down path needs no supervisor helper processes.
      rhino_gate() {
        status_text() {
          if /usr/bin/pgrep -qf "$rhino_bin"; then
            printf 'Rhino is running but this MCP connection predates it. Reconnect the rhino-mcp-platform server (/mcp -> reconnect, or restart the session) to spawn the router and load the full toolset.'
          else
            printf 'Rhino 9 WIP is not running; the rhino-mcp-platform router spawns only against a live Rhino. Run forge-rhino-up (idempotent, splash-free), wait for the app to finish loading, then reconnect the rhino-mcp-platform server (/mcp -> reconnect, or restart the session) to load the full toolset.'
          fi
        }
        local tools_json line method id pv gate_idle_seconds="''${RHINO_MCP_GATE_IDLE_SECONDS:-480}"
        [[ "$gate_idle_seconds" =~ ^[1-9][0-9]*$ ]] || gate_idle_seconds=480
        tools_json='{"tools":[{"name":"rhino_status","description":"Reports the Rhino MCP gate: the full rhino-mcp-platform toolset loads only while Rhino 9 WIP runs. Call this to learn how to bring the toolset up.","inputSchema":{"type":"object","properties":{}}}]}'
        # Streaming boundary: one jq projection per message; the 0x1f join survives absent fields, and a malformed line skips without output.
        while IFS= read -r -t "$gate_idle_seconds" line; do
          [ -n "$line" ] || continue
          IFS=$'\x1f' read -r method id pv < <(printf '%s\n' "$line" | jq -r '
            [(.method // ""), (if has("id") then (.id | tojson) else "" end),
             (.params.protocolVersion // "2025-06-18")] | join("\u001f")' \
            2>/dev/null) || continue
          case "$method" in
            initialize)
              [ -n "$id" ] || continue
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
      }
      rhino_gate
    '';
  };
  # Agent host bootstrap: one splash-free idempotent verb brings RhinoWIP up; the MCP platform listener autostarts with the app, and the router
  # loads the full toolset on the next server (re)connect. `open -a` passes -nosplash only on a fresh launch, so the pgrep guard keeps it honest.
  rhinoUp = pkgs.writeShellApplication {
    name = "forge-rhino-up";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      app="''${RHINO_WIP_APP_PATH:-/Applications/RhinoWIP.app}"
      rhino_bin="$app/Contents/MacOS/Rhinoceros"
      if /usr/bin/pgrep -qf "$rhino_bin"; then
        echo "rhino: running (pid $(/usr/bin/pgrep -f "$rhino_bin" | head -1))"
        exit 0
      fi
      [ -d "$app" ] || { echo "forge-rhino-up: $app not installed" >&2; exit 69; }
      /usr/bin/open -a "$app" --args -nosplash
      for _ in $(seq 1 60); do
        if /usr/bin/pgrep -qf "$rhino_bin"; then
          echo "rhino: launched splash-free (pid $(/usr/bin/pgrep -f "$rhino_bin" | head -1)); reconnect rhino-mcp-platform once loading settles"
          exit 0
        fi
        sleep 0.5
      done
      echo "forge-rhino-up: Rhino did not register within 30s" >&2
      exit 1
    '';
  };
  # updateEngine selects the probe set: only npm-registry rows feed the npm-latest check; a manual or other engine row never emits a false pin row.
  pins =
    builtins.concatStringsSep "\n" (map (r: "${r.launcher.pkg}|${r.launcher.version}")
      (builtins.filter (r: r.launcher.updateEngine == "npm-registry") launcherRows));
  # Full-parity drift program: fleet rows vs both user-owned registrations; Claude secret fields must be environment references, never literals.
  driftJq = pkgs.writeText "mcp-drift.jq" ''
    def env_ref: "$" + "{\(.)}";
    def claude_env:
      ((.claudeEnvNames // .envKeys // []) | map({key: ., value: (. | env_ref)}) | from_entries);
    def claude_headers:
      ((.codex.headerEnv // {}) | with_entries(.value |= env_ref))
      + (if (.codex.bearerEnvVar // null) == null then {}
         else {Authorization: ("Bearer " + (.codex.bearerEnvVar | env_ref))}
         end);
    # Mirror of the projection client-idle derivation so a projected `timeout` reads as clean, not false drift.
    def claude_idle_timeout:
      (.codex.toolTimeoutSec * 1000) as $ms | if $ms > 1800000 then $ms else null end;
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
              | ((if $row.transport == "stdio" then
                  (if ($c.type // "stdio") != "stdio" then ["claude\t\($row.name): claude type != stdio"] else [] end)
                  + (if ($c.command // "") != $row.command then ["claude\t\($row.name): claude command \($c.command // "absent") != \($row.command)"] else [] end)
                  + (if ($c.args // []) != ($row.args // []) then ["claude\t\($row.name): claude args \($c.args // [])"] else [] end)
                  + (if ($c.env // {}) != ($row | claude_env) then ["claude\t\($row.name): claude env inheritance contract drift"] else [] end)
                else
                  (if ($c.type // "") != "http" then ["claude\t\($row.name): claude type != http"] else [] end)
                  + (if ($c.url // "") != $row.url then ["claude\t\($row.name): claude url \($c.url // "absent")"] else [] end)
                  + (if ($c.headers // {}) != ($row | claude_headers) then ["claude\t\($row.name): claude header inheritance contract drift"] else [] end)
                end)
                + (($row | claude_idle_timeout) as $want
                   | if ($c.timeout // null) != $want then ["claude\t\($row.name): claude timeout \($c.timeout // "absent") != \($want // "absent")"] else [] end))
             end)
            + (if ($who | index("codex")) | not then []
               elif $cx[$row.name] == null then ["codex\t\($row.name): MISSING in codex"]
               elif $lvl == "presence" then []
               else ($cx[$row.name]) as $c
                | (if ($c.required // false) != ($row.codex.required // false) then ["codex\t\($row.name): codex required \($c.required // false) != \($row.codex.required // false)"] else [] end)
                  + (if ($c.default_tools_approval_mode // null) != ($row.codex.toolsApprovalMode // null) then ["codex\t\($row.name): codex default_tools_approval_mode \($c.default_tools_approval_mode // "absent") != \($row.codex.toolsApprovalMode // "absent")"] else [] end)
                  + (if ($row.codex.auth // null) == null then []
                     elif ($c.auth // null) != $row.codex.auth then ["codex\t\($row.name): codex auth \($c.auth // "absent") != \($row.codex.auth)"]
                     else [] end)
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
    + (if $codex_oauth_store == "keyring" then []
       else ["codex\tmcp_oauth_credentials_store \($codex_oauth_store // "absent") != keyring"]
       end)
    + (($cl | keys) - [$rows[] | select((.clients // ["claude", "codex"]) | index("claude")) | .name] | map("claude\t\(.): EXTRA in claude (not in manifest)"))
    + (($cx | keys) - [$rows[] | select((.clients // ["claude", "codex"]) | index("codex")) | .name] | map("codex\t\(.): EXTRA in codex (not in manifest)"))
    | .[]
  '';
  # Subset drift for Claude-shaped projection registries such as the VS Code servers map. Registered rows naming a fleet row must honor its contract;
  # commands may spell the launcher basename, and unknown rows are INFO.
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
            # Projections pass env explicitly (no ambient session env), so the expectation is envKeys, never the claudeEnvNames mirror override.
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
  # Desired-registration generator: one program per client shape, all reading the same fleet rows behind full and project-subset drift.
  claudeProjectionJq = pkgs.writeText "mcp-generate-claude.jq" ''
    def env_ref: "$" + "{\(.)}";
    def claude_env:
      ((.claudeEnvNames // .envKeys // []) | map({key: ., value: (. | env_ref)}) | from_entries);
    def claude_headers:
      ((.codex.headerEnv // {}) | with_entries(.value |= env_ref))
      + (if (.codex.bearerEnvVar // null) == null then {}
         else {Authorization: ("Bearer " + (.codex.bearerEnvVar | env_ref))}
         end);
    # Client idle ceiling: Claude Code aborts a silent MCP call at 1800000ms unless the row carries `timeout` (ms). A row whose tool budget outlasts
    # that default projects toolTimeoutSec as milliseconds so the client waits the full budget; the supervisor reaps the subtree once the client
    # generation ends (EOF or client death), and workflow-lane wrappers stall above both. Short-call rows stay under the default, gain no field.
    def claude_idle_timeout:
      (.codex.toolTimeoutSec * 1000) as $ms | if $ms > 1800000 then $ms else null end;
    {
      mcpServers: ([
        .[]
        | select((.clients // ["claude", "codex"]) | index("claude"))
        | select((.assertLevel // "full") == "full")
        | {
            key: .name,
            value: (
              (if .transport == "stdio" then
                {type: "stdio", command, args: (.args // []), env: claude_env}
              else
                {type: "http", url, headers: claude_headers}
              end)
              + (claude_idle_timeout as $t | if $t == null then {} else {timeout: $t} end))
          }
      ] | from_entries),
      managed_names: [.[] | select((.clients // ["claude", "codex"]) | index("claude")) | .name]
    }
  '';
  codexProjectionJq = pkgs.writeText "mcp-generate-codex.jq" ''
    def codex_value:
      (if .transport == "stdio" then
         {command, args: (.args // [])}
         + (if (.envKeys // []) != [] then {env_vars: .envKeys} else {} end)
       else
         {url}
         + (if (.codex.bearerEnvVar // null) != null then {bearer_token_env_var: .codex.bearerEnvVar} else {} end)
         + (if (.codex.headerEnv // null) != null then {env_http_headers: .codex.headerEnv} else {} end)
       end)
      + (if (.codex.auth // null) != null then {auth: .codex.auth} else {} end)
      + (if (.codex.toolsApprovalMode // null) != null then {default_tools_approval_mode: .codex.toolsApprovalMode} else {} end)
      + {
          required: (.codex.required // false),
          startup_timeout_sec: .codex.startupTimeoutSec,
          tool_timeout_sec: .codex.toolTimeoutSec
        };
    {
      mcp_servers: ([
        .[]
        | select((.clients // ["claude", "codex"]) | index("codex"))
        | select((.assertLevel // "full") == "full")
        | {key: .name, value: codex_value}
      ] | from_entries),
      managed_names: [.[] | select((.clients // ["claude", "codex"]) | index("codex")) | .name],
      presence_names: [
        .[]
        | select((.clients // ["claude", "codex"]) | index("codex"))
        | select((.assertLevel // "full") == "presence")
        | .name
      ]
    }
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
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.jq pkgs.yq-go pkgs.findutils pkgs.gawk pkgs.gnugrep pkgs.flock];
    text = ''
      fleet='${fleetJson}'
      receipt_log="''${FORGE_MCP_RECEIPT_LOG:-$HOME/Library/Logs/forge-mcp.receipts.log}"
      vscode_mcp="$HOME/Library/Application Support/Code/User/mcp.json"
      usage() {
        echo "usage: forge-mcp outdated [--json] | doctor [--network] [--json] | drift [--json] | reconcile <claude|codex>" >&2
        echo "       forge-mcp generate <claude|codex|vscode> | roots [--json] | snoop SERVER [-- ARGS...]" >&2
        exit 64
      }
      verb="''${1:-}"; shift || true

      iso_now() { TZ=UTC0 printf '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"; }
      receipt_surface="forge-mcp"
      ${receiptsFold}
      receipt() { # $1=verb $2=result $3=detail
        local ts row
        ts="$(iso_now)"
        printf -v row 'ts=%s\tverb=%s\tresult=%s\tdetail=%s' "$ts" "$1" "$2" "$3"
        append_receipt "$row" || true
      }

      cmd_outdated() {
        as_json=0
        for a in "$@"; do
          case "$a" in
            --json) as_json=1 ;;
            *) usage ;;
          esac
        done
        rc=0 rows=""
        while IFS="|" read -r pkg version; do
          [ -n "$pkg" ] || continue
          if latest="$(curl -fsS --max-time 20 "https://registry.npmjs.org/$(jq -rn --arg p "$pkg" '$p|@uri')/latest" | jq -er .version)"; then
            if [ "$latest" != "$version" ]; then
              rows="$rows"$'\n'"OUTDATED"$'\t'"$pkg"$'\t'"$version"$'\t'"$latest"; rc=1
            else
              rows="$rows"$'\n'"current"$'\t'"$pkg"$'\t'"$version"$'\t'"$latest"
            fi
          else
            # Registry/network failure is not drift: report only.
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
          }' < <(printf '%s\n' "$rows")
        else
          printf '%s\n' "$rows" | while IFS=$'\t' read -r s p v l; do
            printf '%-9s %s pinned=%s latest=%s\n' "$s" "$p" "$v" "$l"
          done
        fi
        receipt outdated "$([ "$rc" = 0 ] && echo ok || echo outdated)" "outdated=$n"
        exit "$rc"
      }

      # Side-effect-free health probe: newline-delimited JSON-RPC initialize on stdio (stdin EOF is the shutdown), POST initialize for bearer/http
      # rows, and Codex app-server inventory for OAuth rows so its credential store performs the authenticated initialize plus tools/list. Values never
      # print. Each probe emits one typed row (STATUS<TAB>name<TAB>detail); presentation is the doctor's, so human and --json share the same rows.
      req='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"forge-mcp-doctor","version":"1.0.0"}}}'
      stop_owned_process() { # process-group leader
        local pid="$1"
        kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          { kill -0 -- "-$pid" 2>/dev/null || kill -0 "$pid" 2>/dev/null; } || break
          sleep 0.1
        done
        if kill -0 -- "-$pid" 2>/dev/null || kill -0 "$pid" 2>/dev/null; then
          kill -KILL -- "-$pid" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
        fi
        wait "$pid" 2>/dev/null || true
      }
      codex_oauth_inventory() { # $1=workdir $2=result-file
        local work="$1" result="$2" oauth_home="$1/codex-oauth-home" fifo="$1/codex-oauth.in" raw="$1/codex-oauth.raw"
        local pid input_fd success=0
        printf '{"ok":false,"reason":"app-server-unavailable","rows":[]}\n' >"$result"
        command -v codex >/dev/null 2>&1 || return 1
        mkdir -p "$oauth_home"
        jq -f '${codexProjectionJq}' "$fleet" \
          | jq '{mcp_oauth_credentials_store: "keyring",
                 mcp_servers: (.mcp_servers | with_entries(select(.value.auth == "oauth")))}' \
          | yq -p json -o toml '.' >"$oauth_home/config.toml"
        if [ "$(yq -p toml -o json '.mcp_servers | length' "$oauth_home/config.toml")" = 0 ]; then
          printf '{"ok":true,"reason":"no-oauth-rows","rows":[]}\n' >"$result"
          return 0
        fi

        mkfifo "$fifo"
        : >"$raw"
        set -m
        CODEX_HOME="$oauth_home" codex app-server --strict-config --stdio <"$fifo" >"$raw" 2>"$work/codex-oauth.err" &
        pid=$!
        set +m
        if ! exec {input_fd}>"$fifo"; then
          stop_owned_process "$pid"
          return 1
        fi
        response_ready() { # $1=id $2=50ms-attempts
          local id="$1" limit="$2" attempt
          for ((attempt = 0; attempt < limit; attempt++)); do
            jq -e --argjson id "$id" 'select(.id == $id)' "$raw" >/dev/null 2>&1 && return 0
            kill -0 "$pid" 2>/dev/null || return 1
            sleep 0.05
          done
          return 1
        }
        if printf '%s\n' \
          '{"id":1,"method":"initialize","params":{"clientInfo":{"name":"forge-mcp-doctor","version":"1.0.0"}}}' >&"$input_fd" \
          && response_ready 1 100 \
          && printf '%s\n' '{"method":"initialized"}' \
            '{"id":2,"method":"mcpServerStatus/list","params":{"detail":"toolsAndAuthOnly"}}' >&"$input_fd" \
          && response_ready 2 600; then
          success=1
        fi
        exec {input_fd}>&-
        stop_owned_process "$pid"
        if [ "$success" = 1 ] && jq -ce '
          select(.id == 2 and (.result.data | type == "array"))
          | {ok: true, reason: "verified", rows: [.result.data[] | {
              name, authStatus,
              toolsListed: (.tools | type == "object"),
              toolCount: (.tools | if type == "object" then length else 0 end),
              serverInfoName: (.serverInfo.name // "")
            }]}
        ' "$raw" >"$result"; then
          return 0
        fi
        printf '{"ok":false,"reason":"authenticated-probe-failed","rows":[]}\n' >"$result"
        return 1
      }

      probe_row() {
        row="$1" network="$2" out="$3" codex_auth="$4" codex_oauth="$5"
        # One jq projection owns the row header; the unit-separator join survives empty fields where tab-IFS reads would collapse them.
        IFS=$'\x1f' read -r name probe transport t cmdpath url bearer auth < <(jq -r \
          '[.name, .probe, .transport, (.codex.startupTimeoutSec // 20 | tostring),
            (.command // ""), (.url // ""), (.codex.bearerEnvVar // ""), (.codex.auth // "")] | join("\u001f")' < <(printf '%s\n' "$row"))
        missing="$(printf '%s\n' "$row" | jq -r '(.envKeys // [])[]' | while IFS= read -r k; do
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
        if [ "$auth" = "oauth" ]; then
          auth_status="$(jq -r --arg name "$name" '[.[] | select(.name == $name) | .auth_status][0] // "unavailable"' "$codex_auth" 2>/dev/null || echo unavailable)"
          if [ "$auth_status" != "o_auth" ]; then
            emit FAIL "Codex OAuth is not usable (status=$auth_status)"; return 0
          fi
          if [ "$(jq -r '.ok // false' "$codex_oauth" 2>/dev/null || echo false)" != true ]; then
            emit FAIL "Codex authenticated MCP probe unavailable"; return 0
          fi
          IFS=$'\x1f' read -r verified_auth tools_listed tool_count server_info < <(jq -r --arg name "$name" '
            [.rows[] | select(.name == $name)
             | [.authStatus, (.toolsListed | tostring), (.toolCount | tostring), .serverInfoName] | join("\u001f")][0] // ""
          ' "$codex_oauth")
          if [ "$verified_auth" != "oAuth" ] || [ "$tools_listed" != true ] || [ -z "$server_info" ]; then
            emit FAIL "Codex authenticated initialize/tools inventory failed"; return 0
          fi
          emit OK "$server_info authenticated, tools=$tool_count"; return 0
        fi
        if [ "$transport" = "stdio" ]; then
          if [ ! -x "$cmdpath" ]; then
            emit FAIL "command not executable: $cmdpath"; return 0
          fi
          mapfile -t argv < <(printf '%s\n' "$row" | jq -r '(.args // [])[]')
          # FIFO stdin: hold the write end open until the response lands, then close it — stdin EOF is the shutdown, so no probe outlives its answer
          # (a sleep-holder would strand every server for the full timeout after doctor returns); timeout backstops mute servers.
          mkfifo "$out.fifo"
          line=""
          exec {rfd}< <(timeout -k 2 "$((t + 2))" "$cmdpath" ''${argv[0]+"''${argv[@]}"} <"$out.fifo" 2>/dev/null || true)
          probe_pid=$!
          exec {wfd}>"$out.fifo"
          printf '%s\n' "$req" >&"$wfd"
          IFS= read -r -t "$t" line <&"$rfd" || true
          exec {wfd}>&-
          exec {rfd}<&-
          wait "$probe_pid" 2>/dev/null || true
          rm -f "$out.fifo"
          if info="$(printf '%s\n' "$line" | jq -er '.result.serverInfo | "\(.name) \(.version // "?")"' 2>/dev/null)"; then
            emit OK "$info$envnote"
          else
            emit FAIL "no initialize response within ''${t}s$envnote"
          fi
        else
          declare -a hdr=()
          if [ -n "$bearer" ]; then
            [ -n "''${!bearer:-}" ] || { emit SKIP "credential env absent: $bearer"; return 0; }
            hdr+=(-H "Authorization: Bearer ''${!bearer}")
          fi
          while IFS=$'\t' read -r h v; do
            [ -n "$h" ] || continue
            [ -n "''${!v:-}" ] || { emit SKIP "credential env absent: $v"; return 0; }
            hdr+=(-H "$h: ''${!v}")
          done < <(printf '%s\n' "$row" | jq -r '(.codex.headerEnv // {}) | to_entries[] | "\(.key)\t\(.value)"')
          # Body temp lives beside the row outfile inside the doctor's trapped tmpdir, so an aborted probe leaves no $TMPDIR litter.
          body="$out.body"
          # curl -w still emits its code line on transport failure; a second echo would corrupt status, so failures fall through to the 000 default.
          code="$(curl -sS --max-time "$t" -o "$body" -w '%{http_code}' -X POST "$url" \
            -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
            -H 'MCP-Protocol-Version: 2025-06-18' ''${hdr[0]+"''${hdr[@]}"} --data "$req" 2>/dev/null || true)"
          [ -n "$code" ] || code=000
          if [ "$code" = 200 ]; then
            payload="$(grep -m1 '^data:' "$body" | cut -c6- || true)"
            [ -n "$payload" ] || payload="$(cat "$body")"
            info="$(printf '%s\n' "$payload" | jq -er '.result.serverInfo | "\(.name) \(.version // "?")"' 2>/dev/null || echo "initialize accepted")"
            emit OK "$info$envnote"
          elif [ "$code" = 401 ] && [ ''${#hdr[@]} -eq 0 ]; then
            emit FAIL "HTTP 401 with no declared credential mechanism$envnote"
          else
            emit FAIL "HTTP $code from initialize$envnote"
          fi
          rm -f "$body"
        fi
      }

      # Named probe families: launcher rows declaring `doctor` get local checks beyond initialize — the Forge launcher name IS the probe row.
      family_rows() { # $1=outfile
        local out="$1"
        while IFS= read -r row; do
          local name
          name="$(jq -r '.name' < <(printf '%s\n' "$row"))"
          while IFS= read -r x; do
            [ -n "$x" ] || continue
            if command -v "$x" >/dev/null 2>&1; then
              printf 'OK\t%s/exec\t%s resolves\n' "$name" "$x" >>"$out"
            else
              printf 'FAIL\t%s/exec\t%s absent from PATH\n' "$name" "$x" >>"$out"
            fi
          done < <(printf '%s\n' "$row" | jq -r '(.doctor.execs // [])[]')
        done < <(jq -c '.[] | select(.doctor)' "$fleet")
      }

      cmd_doctor() {
        if [ -z "''${_FORGE_MCP_DOCTOR_DEADLINE:-}" ]; then
          _FORGE_MCP_DOCTOR_DEADLINE=1 exec timeout -k 5 300 "$0" doctor "$@"
        fi
        network=0 as_json=0
        for a in "$@"; do
          case "$a" in
            --network) network=1 ;;
            --json) as_json=1 ;;
            *) usage ;;
          esac
        done
        tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
        codex_auth="$tmp/codex-auth.json"
        if command -v codex >/dev/null 2>&1 && timeout -k 2 30 codex mcp list --json >"$codex_auth" 2>/dev/null; then
          :
        else
          printf '[]\n' >"$codex_auth"
        fi
        codex_oauth="$tmp/codex-oauth.json"
        if [ "$network" = 1 ] && jq -e 'any(.[]; .codex.auth == "oauth")' "$fleet" >/dev/null; then
          codex_oauth_inventory "$tmp" "$codex_oauth" || true
        else
          printf '{"ok":false,"reason":"network-probe-disabled","rows":[]}\n' >"$codex_oauth"
        fi
        # Wrapper roll-call: every declared fleet wrapper must exist on PATH.
        while IFS= read -r w; do
          if ! command -v "$w" >/dev/null 2>&1; then
            printf 'FAIL\t%s\twrapper absent from PATH\n' "$w" >>"$tmp/wrappers"
          fi
        done < <(jq -r '.[] | (.launcher.names // [])[]' "$fleet")
        family_rows "$tmp/families"
        i=0
        batch_count=0
        declare -a probe_pids=()
        while IFS= read -r row; do
          probe_row "$row" "$network" "$tmp/row.$i" "$codex_auth" "$codex_oauth" &
          probe_pids+=("$!")
          i=$((i + 1))
          batch_count=$((batch_count + 1))
          if [ "$batch_count" -eq 4 ]; then
            for probe_pid in "''${probe_pids[@]}"; do wait "$probe_pid" 2>/dev/null || true; done
            probe_pids=()
            batch_count=0
          fi
        done < <(jq -c '.[]' "$fleet")
        for probe_pid in "''${probe_pids[@]}"; do wait "$probe_pid" 2>/dev/null || true; done
        rows="$tmp/rows"
        {
          [ ! -f "$tmp/wrappers" ] || cat "$tmp/wrappers"
          for ((f = 0; f < i; f++)); do cat "$tmp/row.$f"; done
          [ ! -f "$tmp/families" ] || cat "$tmp/families"
        } >"$rows"
        # Direct file grep: grep -q on the read end of a pipe SIGPIPEs the writer under pipefail, and the negation would swallow real FAILs.
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

      # Three-way registration drift: the manifest is the owner; global Claude/Codex are full mirrors and VS Code is the declared projection. Estate
      # repositories carry no client registration layer, so a switch has one configuration authority per client.
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

        # Registry admission: parse per format, then require an object shape — an absent, unparseable, or wrong-shaped registry is a total-drift
        # finding, never a crash and never a false clean.
        extract_reg() { # $1=json|toml $2=filter $3=file
          case "$1" in
            json) jq "$2" "$3" 2>/dev/null ;;
            toml) yq -p toml -o json "$2" "$3" 2>/dev/null ;;
          esac
        }
        admit_reg() { # $1=json|toml $2=filter $3=file -> object on stdout
          local out
          out="$(extract_reg "$1" "$2" "$3")" || return 1
          printf '%s\n' "$out" | jq -e 'type == "object"' >/dev/null 2>&1 || return 1
          printf '%s' "$out"
        }
        claude_ok=1 codex_ok=1 codex_store=""
        claude_json="$(admit_reg json '.mcpServers // {}' "$HOME/.claude.json")" || { claude_json='{}'; claude_ok=0; }
        if codex_root="$(admit_reg toml '.' "$HOME/.codex/config.toml")"; then
          codex_json="$(printf '%s\n' "$codex_root" | jq -c '.mcp_servers // {}')"
          codex_store="$(printf '%s\n' "$codex_root" | jq -r '.mcp_oauth_credentials_store // ""')"
        else
          codex_json='{}'; codex_ok=0
        fi
        # A drift-program failure on admitted registries is itself a finding; a swallowed rc here would render empty lanes as false-clean.
        jq -rn \
          --slurpfile fleet "$fleet" \
          --slurpfile claude <(printf '%s' "$claude_json") \
          --slurpfile codex <(printf '%s' "$codex_json") \
          --arg codex_oauth_store "$codex_store" \
          -f '${driftJq}' >"$tmp/full" \
          || printf 'claude\tdrift program failed on admitted registries\ncodex\tdrift program failed on admitted registries\n' >>"$tmp/full"
        grep $'^claude\t' "$tmp/full" | cut -f2- >"$tmp/claude.f" || true
        grep $'^codex\t' "$tmp/full" | cut -f2- >"$tmp/codex.f" || true
        [ "$claude_ok" = 1 ] || echo "registry unreadable or wrong-shaped: ~/.claude.json mcpServers" >>"$tmp/claude.f"
        [ "$codex_ok" = 1 ] || echo "registry unreadable or wrong-shaped: ~/.codex/config.toml mcp_servers" >>"$tmp/codex.f"
        printf 'claude|full|1|%s|%s\n' "$([ -s "$tmp/claude.f" ] && echo 0 || echo 1)" "$tmp/claude.f" >>"$tmp/registries"
        printf 'codex|full|1|%s|%s\n' "$([ -s "$tmp/codex.f" ] && echo 0 || echo 1)" "$tmp/codex.f" >>"$tmp/registries"

        subset_lane() { # $1=registry-name $2=json-map $3=jq-program
          local name="$1" json="$2" prog="$3" f="$tmp/$1.f"
          jq -rn --slurpfile fleet "$fleet" --slurpfile reg <(printf '%s' "$json") -f "$prog" >"$f" \
            || echo "projection program failed on admitted registry" >>"$f"
          local drift_lines
          drift_lines="$(grep -cv '^INFO ' "$f" || true)"
          printf '%s|subset|1|%s|%s\n' "$name" "$([ "$drift_lines" = 0 ] && echo 1 || echo 0)" "$f" >>"$tmp/registries"
        }
        # Projection registries are rows (name|file|format|extract|program): a new registry is one row, never a new if/else block.
        while IFS='|' read -r rname rfile rfmt rfilter rprog; do
          if [ ! -f "$rfile" ]; then
            printf '%s|subset|0|1|%s\n' "$rname" /dev/null >>"$tmp/registries"
          elif r_json="$(admit_reg "$rfmt" "$rfilter" "$rfile")"; then
            subset_lane "$rname" "$r_json" "$rprog"
          else
            printf '%s|subset|1|0|%s\n' "$rname" /dev/null >>"$tmp/registries"
          fi
        done < <(printf '%s\n' \
          "vscode|$vscode_mcp|json|.servers // {}|${subsetClaudeJq}")

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
        receipt drift "$([ "$rc" = 0 ] && echo clean || echo drift)" "registries=$(wc -l <"$tmp/registries" | tr -d ' ')"
        exit "$rc"
      }

      # Declarative client projection: the manifest replaces its MCP map, client-private presence rows survive, and unadmitted rows fail closed. One
      # lock serializes Forge writers; a bounded optimistic compare/stability/publish/readback loop re-merges client writes instead of erasing them.
      cmd_reconcile() {
        client="''${1:-}"
        [ "$client" = claude ] || [ "$client" = codex ] || usage
        lock_root="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}"
        mkdir -p "$lock_root"
        exec {reconcile_lock_fd}>"$lock_root/forge-mcp-reconcile-$UID.lock"
        if ! flock -w 15 "$reconcile_lock_fd"; then
          receipt reconcile fail "lock-timeout"
          echo "forge-mcp reconcile: another reconciler held the lock for 15s" >&2
          exit 75
        fi

        source_matches() { # $1=config $2=snapshot $3=had-config
          if [ "$3" = 1 ]; then cmp -s "$1" "$2"; else [ ! -e "$1" ]; fi
        }
        publish_attempt() { # $1=config $2=snapshot $3=rendered $4=expected $5=had-config
          source_matches "$1" "$2" "$5" || return 1
          sleep 0.05
          source_matches "$1" "$2" "$5" || return 1
          cp "$3" "$4"
          mv "$3" "$1"
          sleep 0.05
          cmp -s "$1" "$4"
        }

        if [ "$client" = claude ]; then
          cfg="$HOME/.claude.json"
          mkdir -p "''${cfg%/*}"
          tmp="$(mktemp -d "''${cfg%/*}/.forge-mcp-reconcile.XXXXXX")"; trap 'rm -rf "$tmp"' EXIT
          projection="$(jq -f '${claudeProjectionJq}' "$fleet")"
          for attempt in 1 2 3 4 5; do
            source="$tmp/source.$attempt"; rendered="$tmp/rendered.$attempt"; expected="$tmp/expected.$attempt"; had_cfg=0
            if [ -e "$cfg" ]; then
              had_cfg=1
              cp "$cfg" "$source"
              current="$(jq '.' "$source")" || {
                receipt reconcile fail "claude-config-unparseable"
                echo "forge-mcp reconcile: $cfg is not valid JSON" >&2
                exit 65
              }
            else
              : >"$source"; current='{}'
            fi
            extras="$(jq -rn --argjson current "$current" --argjson projection "$projection" \
              '(($current.mcpServers // {} | keys) - $projection.managed_names) | join(" ")')"
            if [ -n "$extras" ]; then
              receipt reconcile fail "unadmitted-claude-rows"
              echo "forge-mcp reconcile: unadmitted Claude MCP rows: $extras" >&2
              exit 65
            fi
            merged="$(jq -cn --argjson current "$current" --argjson projection "$projection" \
              '$current | .mcpServers = $projection.mcpServers')"
            if [ "$(printf '%s\n' "$current" | jq -Sc .)" = "$(printf '%s\n' "$merged" | jq -Sc .)" ]; then
              receipt reconcile ok "claude-config-unchanged"
              echo "forge-mcp reconcile: Claude projection already current"
              return 0
            fi
            printf '%s\n' "$merged" | jq '.' >"$rendered"
            chmod 0600 "$rendered"
            if publish_attempt "$cfg" "$source" "$rendered" "$expected" "$had_cfg"; then
              receipt reconcile ok "claude-config-updated-attempt=$attempt"
              echo "forge-mcp reconcile: Claude projection updated"
              return 0
            fi
          done
          receipt reconcile fail "claude-config-write-contention"
          echo "forge-mcp reconcile: $cfg kept changing across five merge attempts" >&2
          exit 75
        fi
        codex_home="''${CODEX_HOME:-$HOME/.codex}"
        cfg="$codex_home/config.toml"
        mkdir -p "$codex_home"
        tmp="$(mktemp -d "$codex_home/.forge-mcp-reconcile.XXXXXX")"; trap 'rm -rf "$tmp"' EXIT
        projection="$(jq -f '${codexProjectionJq}' "$fleet")"
        for attempt in 1 2 3 4 5; do
          source="$tmp/source.$attempt"; rendered="$tmp/rendered.$attempt"; expected="$tmp/expected.$attempt"; had_cfg=0
          if [ -e "$cfg" ]; then
            had_cfg=1
            cp "$cfg" "$source"
            current="$(yq -p toml -o json '.' "$source")" || {
              receipt reconcile fail "codex-config-unparseable"
              echo "forge-mcp reconcile: $cfg is not valid TOML" >&2
              exit 65
            }
          else
            : >"$source"; current='{}'
          fi
          extras="$(jq -rn --argjson current "$current" --argjson projection "$projection" \
            '(($current.mcp_servers // {} | keys) - $projection.managed_names) | join(" ")')"
          if [ -n "$extras" ]; then
            receipt reconcile fail "unadmitted-codex-rows"
            echo "forge-mcp reconcile: unadmitted Codex MCP rows: $extras" >&2
            exit 65
          fi
          merged="$(jq -cn --argjson current "$current" --argjson projection "$projection" '
            ($projection.presence_names | reduce .[] as $name ({};
              if $current.mcp_servers[$name] == null then . else .[$name] = $current.mcp_servers[$name] end)) as $presence
            | $current
            | .mcp_oauth_credentials_store = "keyring"
            | .mcp_servers = ($projection.mcp_servers + $presence)
            | del(.features.js_repl)          # retired feature row: reconcile strips it wherever the app re-persists it
          ')"
          if [ "$(printf '%s\n' "$current" | jq -Sc .)" = "$(printf '%s\n' "$merged" | jq -Sc .)" ]; then
            receipt reconcile ok "codex-config-unchanged"
            echo "forge-mcp reconcile: Codex projection already current"
            return 0
          fi
          printf '%s\n' "$merged" | yq -p json -o toml '.' >"$rendered"
          yq -p toml -o json '.' "$rendered" >/dev/null
          chmod 0600 "$rendered"
          if publish_attempt "$cfg" "$source" "$rendered" "$expected" "$had_cfg"; then
            receipt reconcile ok "codex-config-updated-attempt=$attempt"
            echo "forge-mcp reconcile: Codex projection updated"
            return 0
          fi
        done
        receipt reconcile fail "codex-config-write-contention"
        echo "forge-mcp reconcile: $cfg kept changing across five merge attempts" >&2
        exit 75
      }

      # Desired-registration generator: Claude values are environment references and Codex values are env NAMES; neither shape materializes secrets.
      cmd_generate() {
        case "''${1:-}" in
          claude) jq -f '${claudeProjectionJq}' "$fleet" | jq '{mcpServers}' ;;
          codex) jq -f '${codexProjectionJq}' "$fleet" | jq '{mcp_servers}' | yq -p json -o toml '.' ;;
          vscode) jq -f '${generateVscodeJq}' "$fleet" ;;
          *) usage ;;
        esac
      }

      # Agent-root observability: runtime corpus facts (counts + sizes) for the retention board. Read-only; class names are the retention rows.
      cmd_roots() {
        as_json=0; [ "''${1:-}" != "--json" ] || as_json=1
        scan() { # $1=root $2=class $3=path
          local files kb
          [ -e "$3" ] || return 0
          # Guarded folds: a root vanishing or turning unreadable mid-scan is expected non-zero, one scalar per probe, never a killed verb.
          files="$({ find "$3" -type f 2>/dev/null || true; } | wc -l | tr -d ' ')"
          kb="$({ du -sk "$3" 2>/dev/null || true; } | awk 'NR == 1 {s = $1} END {print s + 0}')"
          printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "''${3/#"$HOME"/\~}" "$files" "$kb"
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
          }' < <(printf '%s\n' "$rows")
        else
          printf '%-10s %-14s %-42s %10s %12s\n' ROOT CLASS PATH FILES KB
          printf '%s\n' "$rows" | while IFS=$'\t' read -r r c p f k; do
            printf '%-10s %-14s %-42s %10s %12s\n' "$r" "$c" "$p" "$f" "$k"
          done
        fi
        receipt roots ok "rows=$(printf '%s\n' "$rows" | grep -c . || true)"
      }

      # Gated traffic capture: opt-in env required, frame metadata only (direction, kind, method, id, bytes — params/results never persist), logs age
      # out at ${toString snoopPolicy.retentionDays}d; capture without the policy gate is unreachable.
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
        TZ=UTC0 printf -v snap '%(%Y%m%dT%H%M%SZ)T' "$EPOCHSECONDS"
        log="$logdir/$server.$snap.jsonl"
        cmdpath="$(printf '%s\n' "$row" | jq -r '.command')"
        mapfile -t argv < <(printf '%s\n' "$row" | jq -r '(.args // [])[]')
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
        reconcile) cmd_reconcile "$@" ;;
        generate) cmd_generate "$@" ;;
        roots) cmd_roots "$@" ;;
        snoop) cmd_snoop "$@" ;;
        *) usage ;;
      esac
    '';
  };

  # Completion projection for the fleet surface.
  mcpCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-mcp" ''
    #compdef forge-mcp
    _arguments \
      '1:verb:(outdated doctor drift reconcile generate roots snoop)' \
      '--network[probe network-class rows]' \
      '--json[schema=forge-mcp/v1 receipt]'
  '';
in {
  config = {
    home.packages = launchers ++ [forgeSuperviseStdio maghzPostgres rhinoRouter rhinoUp forgeMcp mcpCompletion pkgs.mcp-nixos];

    # Each Darwin switch reasserts the fleet maps while preserving non-MCP client state; Codex app-private rows remain presence-owned by ChatGPT.
    home.activation.forgeMcpReconcile = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${forgeMcp}/bin/forge-mcp reconcile claude
      run ${forgeMcp}/bin/forge-mcp reconcile codex
    '');
  };
}
