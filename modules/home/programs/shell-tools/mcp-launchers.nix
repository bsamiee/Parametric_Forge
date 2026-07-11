# Title         : mcp-launchers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mcp-launchers.nix
# ----------------------------------------------------------------------------
# Data-plane owner: builds pinned pnpm launchers from mcp-fleet.nix rows and ships the fleet/agent observability surface — `forge-mcp` emitting
# schema=forge-mcp/v1 receipts, plus `forge-agents`, the collector folding the main-agent lifecycle feed (hook rows), bells, and standing estate
# alerts into cached facts: named zjstatus bar cells, in-pane attention marks reconciled by pane id, and the banner/alerter answer channel.
# Session state is lifecycle-pure — event order per session_id, never a process census. Bar code never touches providers or credentials.
{
  config,
  lib,
  pkgs,
  ...
}: let
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  stateHome = config.xdg.stateHome;
  # Shared owners: notifier + alerter rails and identity bundles (bundle-apps.nix), the dual-receipt emit fold (receipts.nix), the F01 attention
  # vocabulary (attention.nix), and the platform ps dispatch (/bin/ps is a Darwin fact; NixOS gets procps by store path) — ps serves ONLY the
  # focus click's host-app ancestry walk, never session state; the attention fold is lifecycle-pure.
  tnBin = config.forge.notifier;
  alerterBin = config.forge.alerter;
  receiptsFold = import ./receipts.nix;
  attention = import ./attention.nix {sshHosts = config.forge.ssh.hosts;};
  # Standing-alert rows join their receipt-registry paths at eval; an alert row naming an unregistered kind is a wiring defect, not a runtime skip.
  alertRows =
    map (
      row: let
        reg = lib.findFirst (r: r.kind == row.kind) null config.forge.registers.receiptSources;
      in
        assert lib.assertMsg (reg != null) "forge-agents: alert row kind '${row.kind}' has no receipt-registry row";
          row // {inherit (reg) path grain;}
    )
    attention.alertRows;
  alertsJson = pkgs.writeText "forge-agents-alerts.json" (builtins.toJSON alertRows);
  psBin =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/bin/ps"
    else "${pkgs.procps}/bin/ps";
  inherit (config.forge.theme) roles icons; # Estate palette owner (modules/home/theme.nix): roles + the closed status-glyph alphabet
  td = config.forge.theme.projections.timeDisplay; # Display-time grammar rows: HH:MM local same-day, dd/mm HH:MM otherwise
  # Pane-mark sentinel: the ascii attention marker widened by a zero-width-space discriminator — renders as "[?] " yet is byte-impossible to type
  # in a rename prompt, so the reconcile sweep owns exactly the titles it minted and an operator title spelled "[?] ..." is never unmarked.
  markSentinel = "${icons.alphabet.attention.ascii}${builtins.fromJSON ''"\u200b"''} ";
  fleet = import ./mcp-fleet.nix {
    inherit profileBin;
    homeDir = config.home.homeDirectory;
    sshBin = "${pkgs.openssh}/bin/ssh";
  };
  launcherRows = builtins.filter (r: r ? launcher) fleet;
  fleetJson = pkgs.writeText "mcp-fleet.json" (builtins.toJSON fleet);
  # Shared supervised stdio lane (relay-cat + group reap): every launcher ties its server subtree to client liveness, so a dead or reconnecting
  # client leaves zero residue — fleet servers demonstrably ignore stdin EOF and otherwise outlive their closed pipes for hours.
  superviseStdio = import ./supervise-stdio.nix;

  # Traffic-capture policy rows (annex-gated): capture is unreachable without the opt-in env, frames log metadata only, and files age out.
  snoopPolicy = {
    optInEnv = "FORGE_MCP_DEBUG";
    redaction = "frame-metadata-only"; # direction, method, id, kind, bytes — never params/results
    retentionDays = 7;
    logDir = "${stateHome}/forge-mcp-snoop";
  };
  # Notification policy rows for the collector projections: per-source arms select the renderer by interaction contract. A needs-input rise posts a
  # replaceable banner whose click opens the alerter answer channel (bare focus off-Darwin); a standing-alert rise posts a banner plus the in-bar
  # toast; bell rows render as a bar count only, since the WezTerm bell arm already owns the bell toast.
  notifyPolicy = {
    needsInput = true;
    alerts = true;
    minIntervalSec = 300;
    bellWindowSec = 900;
    # Stale guard only, never the signal: lifecycle events carry the waiting state; the window merely retires a session that emitted a
    # Notification and then went dark with no clearing event (killed mid-prompt, detached host). Dead zellij sessions prune faster by liveness.
    staleWindowSec = 3600;
    answerTimeoutSec = 120;
    clickVerb =
      if alerterBin != ""
      then "answer"
      else "focus";
    # Cross-device tier (ntfy): per-class publish rows the same rise gates drive; the target rides the NTFY_URL/NTFY_TOPIC/NTFY_TOKEN
    # Doppler rows, and absent custody degrades to local-only.
    remote = {
      needsInput = {
        priority = "high";
        tags = "forge,question";
      };
      alerts = {
        priority = "high";
        tags = "forge,warning";
      };
    };
  };
  # Collector-side payload arm per bar pipe row (forge.agents.statusPipes below is the vocabulary; the zellij bar derives its {pipe_*} lane from
  # the same rows). The assert breaks eval when an arm and the vocabulary drift, so a renamed or added cell cannot silently drop off either side.
  pipePayloads = {
    alerts = "$alerts_cell";
    agents = "$agents_cell";
    session = "#[bg=${roles.accent.tertiary.hex},fg=${roles.text.inverse.hex},bold] __SESSION__ ";
  };
  statusPipes = ["alerts" "agents" "session"];
  pipeBroadcast = assert lib.assertMsg (lib.naturalSort (lib.attrNames pipePayloads) == lib.naturalSort statusPipes)
  "forge-agents: collector payload arms [${lib.concatStringsSep " " (lib.attrNames pipePayloads)}] drift from statusPipes [${lib.concatStringsSep " " statusPipes}]";
    lib.concatMapStringsSep " \\\n                " (p: "\"zjstatus::pipe::pipe_${p}::${pipePayloads.${p}}\"") statusPipes;
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
        ${superviseStdio ''"$entry"''}
      fi

      # Thin responder: newline-delimited JSON-RPC over stdio at near-zero cost. tools/call re-probes Rhino so an agent that started it mid-session
      # reads live state plus the reconnect instruction; stdin EOF is the shutdown, so the shim can never outlive its client.
      status_text() {
        if /usr/bin/pgrep -qf "$rhino_bin"; then
          printf 'Rhino is running but this MCP connection predates it. Reconnect the rhino-mcp-platform server (/mcp -> reconnect, or restart the session) to spawn the router and load the full toolset.'
        else
          printf 'Rhino 9 WIP is not running; the rhino-mcp-platform router spawns only against a live Rhino. Start it (open -a RhinoWIP), wait for the app to finish loading, then reconnect the rhino-mcp-platform server (/mcp -> reconnect, or restart the session) to load the full toolset.'
        fi
      }
      tools_json='{"tools":[{"name":"rhino_status","description":"Reports the Rhino MCP gate: the full rhino-mcp-platform toolset loads only while Rhino 9 WIP runs. Call this to learn how to bring the toolset up.","inputSchema":{"type":"object","properties":{}}}]}'
      # Streaming boundary: one jq projection per message; the 0x1f join survives absent fields, and a malformed line skips without output.
      while IFS= read -r line; do
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
                  + (if ($c.env // {}) != ($row | claude_env) then ["claude\t\($row.name): claude env inheritance contract drift"] else [] end)
                else
                  (if ($c.type // "") != "http" then ["claude\t\($row.name): claude type != http"] else [] end)
                  + (if ($c.url // "") != $row.url then ["claude\t\($row.name): claude url \($c.url // "absent")"] else [] end)
                  + (if ($c.headers // {}) != ($row | claude_headers) then ["claude\t\($row.name): claude header inheritance contract drift"] else [] end)
                end)
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
    {
      mcpServers: ([
        .[]
        | select((.clients // ["claude", "codex"]) | index("claude"))
        | select((.assertLevel // "full") == "full")
        | {
            key: .name,
            value: (
              if .transport == "stdio" then
                {type: "stdio", command, args: (.args // []), env: claude_env}
              else
                {type: "http", url, headers: claude_headers}
              end)
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
        echo "usage: forge-mcp outdated [--notify] [--json] | doctor [--network] [--json] | drift [--json] | reconcile <claude|codex>" >&2
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
          [ -n "$pkg" ] || continue
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
          }' < <(printf '%s\n' "$rows")
        else
          printf '%s\n' "$rows" | while IFS=$'\t' read -r s p v l; do
            printf '%-9s %s pinned=%s latest=%s\n' "$s" "$p" "$v" "$l"
          done
        fi
        tn='${tnBin}'
        if [ "$notify" = 1 ] && [ "$rc" = 1 ] && [ -n "$tn" ]; then
          "$tn" -title "Forge MCP pins" \
            -message "$n MCP pin(s) behind npm latest - run forge-mcp outdated" \
            -group forge-mcp-pins >/dev/null 2>&1 || true
        fi
        receipt outdated "$([ "$rc" = 0 ] && echo ok || echo outdated)" "outdated=$n"
        exit "$rc"
      }

      # Side-effect-free health probe: newline-delimited JSON-RPC initialize on stdio (stdin EOF is the shutdown), POST initialize for bearer/http
      # rows, and Codex app-server inventory for OAuth rows so its credential store performs the authenticated initialize plus tools/list. Values never
      # print. Each probe emits one typed row (STATUS<TAB>name<TAB>detail); presentation is the doctor's, so human and --json share the same rows.
      req='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"forge-mcp-doctor","version":"1.0.0"}}}'
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
        CODEX_HOME="$oauth_home" codex app-server --strict-config --stdio <"$fifo" >"$raw" 2>"$work/codex-oauth.err" &
        pid=$!
        if ! exec {input_fd}>"$fifo"; then
          kill "$pid" 2>/dev/null || true
          wait "$pid" 2>/dev/null || true
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
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
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
          exec {rfd}< <(timeout "$((t + 2))" "$cmdpath" ''${argv[0]+"''${argv[@]}"} <"$out.fifo" 2>/dev/null || true)
          exec {wfd}>"$out.fifo"
          printf '%s\n' "$req" >&"$wfd"
          IFS= read -r -t "$t" line <&"$rfd" || true
          exec {wfd}>&-
          exec {rfd}<&-
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
          local name label port token lctl pid
          # One projection per doctor-row snapshot; 0x1f join survives empties.
          IFS=$'\x1f' read -r name label port token < <(jq -r \
            '[.name, (.doctor.launchdLabel // ""), (.doctor.port // "" | tostring), (.doctor.tokenFile // "")] | join("\u001f")' < <(printf '%s\n' "$row"))
          if [ -n "$label" ]; then
            # launchd rows are Darwin facts; a systemd host skips them typed.
            if [ ! -x /bin/launchctl ]; then
              printf 'SKIP\t%s/launchd\tno launchd on this host\n' "$name" >>"$out"
            elif lctl="$(/bin/launchctl print "gui/$(id -u)/$label" 2>/dev/null)"; then
              pid="$(printf '%s\n' "$lctl" | awk '/^[[:space:]]*pid = /{if (p == "") p = $3} END{print p}')"
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
            if (exec {tcp_fd}<>"/dev/tcp/127.0.0.1/$port" && exec {tcp_fd}>&-) 2>/dev/null; then
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
          done < <(printf '%s\n' "$row" | jq -r '(.doctor.execs // [])[]')
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
        codex_auth="$tmp/codex-auth.json"
        if command -v codex >/dev/null 2>&1 && codex mcp list --json >"$codex_auth" 2>/dev/null; then
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
        while IFS= read -r row; do
          probe_row "$row" "$network" "$tmp/row.$i" "$codex_auth" "$codex_oauth" &
          i=$((i + 1))
        done < <(jq -c '.[]' "$fleet")
        wait
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

  # --- [FORGE_AGENTS]
  # One data owner folds the main-agent lifecycle feed (hook rows: Notification opens WAITING; UserPromptSubmit/PostToolUse/Stop clear;
  # SessionEnd retires), bells, and standing estate alerts into one cached fact set; the zjstatus top bar renders named cells and the
  # {notifications} toast, the waiting pane itself carries a reversible frame-title mark (rename-pane by id, reconciled each tick), the
  # desktop banner rides terminal-notifier, and the alerter answer channel closes the loop — one fold, five renderers, per-source policy
  # rows. A banner click routes back via `answer`/`focus`. State derives from event order per session_id, never from a process census.
  forgeAgents = pkgs.writeShellApplication {
    name = "forge-agents";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.jq pkgs.findutils pkgs.gawk pkgs.gnugrep pkgs.flock];
    text = ''
            state_root="''${XDG_STATE_HOME:-$HOME/.local/state}/forge"
            cache="$state_root/agent-state.json"
            meta="$state_root/agent-collect.meta.json"
            feed="''${FORGE_ATTENTION_FEED:-$state_root/agent-attention.jsonl}"
            lanes_out="''${XDG_CACHE_HOME:-$HOME/.cache}/forge/agent-lanes.json"
            receipt_log="''${FORGE_AGENTS_RECEIPT_LOG:-$HOME/Library/Logs/forge-agents.receipts.log}"
            usage() { echo "usage: forge-agents collect | status [--json] | focus | answer" >&2; exit 64; }
            verb="''${1:-status}"; shift || true
            # Whole-body deadline under the 60s tick: a collector wedged on any stage dies before the next tick instead of holding the flock forever.
            if [ "$verb" = collect ] && [ -z "''${_FORGE_AGENTS_DEADLINE:-}" ]; then
              _FORGE_AGENTS_DEADLINE=1 exec timeout -k 10 55 "$0" collect
            fi

            iso_now() { TZ=UTC0 printf '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"; }
            receipt_surface="forge-agents"
            ${receiptsFold}
            # Shared F01 vocabulary (attention.nix): urgency ladder, kv parser, session key, latest-needs fold — $-bearing jq text as single-quoted data by design.
            # shellcheck disable=SC2016
            jq_defs=${lib.escapeShellArg (attention.urgencyJq + attention.kvJq + attention.sessionKeyJq + attention.latestNeedsJq)}
            alerts_catalog='${alertsJson}'

            cmd_status() {
              if [ ! -f "$cache" ]; then
                echo "forge-agents: no cache yet; run forge-agents collect" >&2
                exit 1
              fi
              if [ "''${1:-}" = "--json" ]; then
                jq . "$cache"
              else
                # Human render only: stored stamps stay ISO UTC in the cache; the display-time grammar (theme owner rows) renders them, and a
                # malformed stamp passes through untouched.
                jq -r '${attention.dispTsJq td}
                  "as-of      \(.ts | disp_ts)",
                  "sessions   live=\(.sessions | length) waiting=\(.attention.needs_input // 0) alerts=\(.alerts.count // 0) bells=\(.bells.count // 0)",
                  (.attention.waiting[]? | "  waiting: \(.label) pane=\(.zellij_pane // "-") since \(.ts | disp_ts)\(if (.message // "") != "" then " — \(.message | .[0:80])" else "" end)"),
                  (.alerts.rows[]? | "  alert: \(.label) since \(.ts // "-" | disp_ts)"),
                  (.sessions[]? | "  session: \(.lane) state=\(.state) seen=\(.ts | disp_ts)")
                ' "$cache"
              fi
            }

            cmd_collect() {
              mkdir -p "$state_root" "$(dirname "$lanes_out")"
              # One collector at a time, bounded queue: a hook kick landing while a tick is mid-fold WAITS for the lock and re-folds the fresh
              # row instead of dropping the edge to the next 60s tick; every section below is a snapshot-fold, so a queued rerun is idempotent.
              exec {collect_fd}>"$state_root/.collect.lock"
              flock -w 10 "$collect_fd" || exit 0
              now="$EPOCHSECONDS"
              ts="$(iso_now)"
              # Tolerant admission: a torn or foreign cache/meta file folds to {} instead of killing the collector under set -e.
              prev="$(jq -c 'if type == "object" then . else {} end' "$cache" 2>/dev/null)" || prev='{}'
              m="$(jq -c 'if type == "object" then . else {} end' "$meta" 2>/dev/null)" || m='{}'

              # ONE zellij session snapshot serves the fold's liveness prune, the pane-mark reconcile, and the pipe broadcast.
              live_sessions="$(${profileBin}/zellij list-sessions -ns 2>/dev/null || true)"
              live_json="$(printf '%s\n' "$live_sessions" | jq -Rcs 'split("\n") | map(select(length > 0))')"

              # --- [LIFECYCLE_FOLD]
              # ONE feed snapshot, ONE jq, lifecycle-pure: per session the LATEST hook row is the state — Notification = waiting,
              # UserPromptSubmit/PostToolUse = active, Stop = idle, SessionEnd = gone. Clearing events outstamp the Notification they answer, so
              # max_by(.ts) encodes every transition (same-second ties break to append order); dedupe is group_by(session_key) — session_id
              # widened by terminal identity for anonymous rows — so stacked tabs never inflate, a reattached tty never drops a waiter, and two
              # anonymous sessions never clear each other. A session naming a dead zellij session prunes on liveness; the stale window retires a
              # waiter that went dark with no clearing event, degrading its lane to idle rather than lying waiting forever. source=bell rows
              # (WezTerm bell arm) count inside their own policy window — the deck toast owns the bell's desktop surface — and fromjson? rails
              # the live-appended, lock-free-rotated feed.
              TZ=UTC0 printf -v att_cut '%(%Y-%m-%dT%H:%M:%SZ)T' "$((now - ${toString notifyPolicy.staleWindowSec}))"
              TZ=UTC0 printf -v bell_cut '%(%Y-%m-%dT%H:%M:%SZ)T' "$((now - ${toString notifyPolicy.bellWindowSec}))"
              feed_facts="$(tail -n 2000 "$feed" 2>/dev/null | jq -Rcn \
                --arg cut "$att_cut" --arg bcut "$bell_cut" --argjson live "$live_json" "$jq_defs"'
                [inputs | fromjson? | select(type == "object")] as $rows
                | ([$rows[] | select((.source // "hook") == "hook")] | group_by(session_key) | map(max_by(.ts))) as $latest
                | ($latest | map(select(.event != "SessionEnd"
                    and (((.zellij_session // "") == "") or (.zellij_session as $s | $live | index($s)))))) as $alive
                | {
                    sessions: [$alive[] | {session_id, zellij_session, zellij_pane, ts,
                      state: (if .event == "Notification" then (if .ts >= $cut then "waiting" else "idle" end)
                              elif .event == "Stop" then "idle" else "active" end),
                      lane: (if (.zellij_session // "") != "" then "\(.zellij_session)·p\(.zellij_pane)"
                             else (.session_id | tostring | .[0:8]) end)}],
                    waiting: [$alive[] | select(.event == "Notification" and .ts >= $cut)],
                    bells: ([$rows[] | select((.source // "") == "bell" and .ts >= $bcut)]
                            | {count: length, latest: (max_by(.ts) // null)})
                  }' 2>/dev/null)" \
                || feed_facts='{"sessions": [], "waiting": [], "bells": {"count": 0, "latest": null}}'
              sessions="$(printf '%s\n' "$feed_facts" | jq -c '.sessions')"
              bells="$(printf '%s\n' "$feed_facts" | jq -c '.bells')"
              bells_n="$(printf '%s\n' "$feed_facts" | jq -r '.bells.count')"

              # --- [PANE_SNAPSHOT_AND_WAITER_IDENTITY]
              # ONE list-panes snapshot per live zellij session (usually one or two) resolves pane id -> tab + live frame title, so the bar
              # cell, banner, alerter, and pane mark all NAME the waiter (SESSION·T<n>) AND the mark reconcile below reads displayed truth for
              # every pane — the full snapshot is what makes the leaked-mark sweep possible. A dead session folds to an empty pane set.
              panes='{}'
              while IFS= read -r zs; do
                [ -n "$zs" ] || continue
                p="$(${profileBin}/zellij --session "$zs" action list-panes --all --json 2>/dev/null || true)"
                printf '%s\n' "$p" | jq -e 'type == "array"' >/dev/null 2>&1 || p='[]'
                panes="$(jq -c --arg zs "$zs" --argjson p "$p" \
                  '.[$zs] = ($p | map(select(.is_plugin | not) | {id, tab_position, title}))' < <(printf '%s\n' "$panes"))"
              done <<<"$live_sessions"
              att="$(jq -c --argjson panes "$panes" '
                [.waiting[] | . as $w
                 | (first(($panes[$w.zellij_session // ""] // [])[] | select((.id | tostring) == ($w.zellij_pane // ""))) // null) as $p
                 | $w + {tab: (if $p then ($p.tab_position + 1) else null end), title: ($p.title // "")}
                 | . + {label: (if (.zellij_session // "") != ""
                     then ((.zellij_session | ascii_upcase) + (if .tab then "·T\(.tab)" else "" end))
                     else (.session_id | tostring | .[0:6]) end)}]
                | {needs_input: length, waiting: ., latest: (max_by(.ts) // null)}' < <(printf '%s\n' "$feed_facts"))"
              needs="$(printf '%s\n' "$att" | jq -r '.needs_input')"

              # --- [ALERTS_STANDING_ESTATE_CONDITIONS]
              # Catalog rows (attention.nix joined to the receipt registry): each predicate judges the LAST receipt row of its kind, so an alert
              # stands until a newer row clears it — estate state, not a windowed event. One jq per row; rows are Nix-owned data.
              alerts="$(while IFS=$'\x1f' read -r a_source a_kind a_pred a_label a_path a_grain; do
                f="$HOME/$a_path"
                [ -f "$f" ] || continue
                last="$(tail -n 1 "$f" 2>/dev/null || true)"
                [ -n "$last" ] || continue
                case "$a_grain" in
                  json) a_parse='(fromjson? // {})' ;;
                  *) a_parse='kv_row' ;;
                esac
                jq -Rc --arg source "$a_source" --arg kind "$a_kind" --arg label "$a_label" \
                  "$jq_defs $a_parse | select($a_pred) | {source: \$source, kind: \$kind, label: \$label, ts: (.ts // null), state: (.state // .deployed // .result // null)}" \
                  < <(printf '%s\n' "$last") 2>/dev/null || true
              done < <(jq -r '.[] | [.source, .kind, .pred, .label, .path, .grain] | join("\u001f")' "$alerts_catalog") \
                | jq -sc '.')"
              [ -n "$alerts" ] || alerts='[]'
              alerts_n="$(printf '%s\n' "$alerts" | jq -r 'length')"

              # --- [CACHE_ASSEMBLY]
              tmp_cache="$cache.tmp.$$"
              jq -cn --arg ts "$ts" --argjson sessions "$sessions" --argjson att "$att" \
                --argjson bells "$bells" --argjson alerts "$alerts" '{
                schema: "forge-agents/v2", ts: $ts,
                sessions: $sessions,
                attention: $att,
                bells: $bells,
                alerts: {count: ($alerts | length), rows: $alerts}
              }' >"$tmp_cache"
              mv "$tmp_cache" "$cache"

              # --- [PANE_MARK_RECONCILE]
              # The waiting pane itself is the primary attention surface: each waiter's frame title gains a reversible sentinel mark by pane id
              # (off-focus, cross-session, no focus theft); undo-rename-pane restores the auto title the moment the clearing event lands.
              # Displayed titles are the ground truth the reconcile reads — a pane counts as system-marked iff its live title opens with the
              # SENTINEL (ascii marker + zero-width discriminator, untypeable in a rename prompt) — so a crash mid-tick can never nest a second
              # marker, no state file can leak a mark (the sweep over the full snapshot unmarks any stray sentinel no waiter owns), and an
              # operator title spelled "[?] ..." is never mistaken for a mark or clobbered. Entrant titles strip a prior sentinel before
              # prefixing; a dead session or pane degrades to a benign no-op.
              mark_pfx="${markSentinel}"
              declare -A want_mark=()
              while IFS=$'\t' read -r w_zs w_zp w_title; do
                [ -n "$w_zs" ] && [ -n "$w_zp" ] || continue
                w_title="''${w_title#"$mark_pfx"}"
                want_mark["$w_zs"$'\x1f'"$w_zp"]="''${w_title:-input needed}"
              done < <(jq -r '.attention.waiting[]?
                | select(((.zellij_session // "") != "") and ((.zellij_pane // "") != ""))
                | [.zellij_session, .zellij_pane, (.title // "")] | @tsv' "$cache")
              while IFS=$'\t' read -r p_zs p_zp p_title; do
                [ -n "$p_zs" ] && [ -n "$p_zp" ] || continue
                mk="$p_zs"$'\x1f'"$p_zp"
                if [ -n "''${want_mark[$mk]+x}" ]; then
                  [ "''${p_title:0:''${#mark_pfx}}" = "$mark_pfx" ] \
                    || ${profileBin}/zellij --session "$p_zs" action rename-pane --pane-id "$p_zp" \
                      "$mark_pfx''${want_mark[$mk]:0:40}" 2>/dev/null || true
                elif [ "''${p_title:0:''${#mark_pfx}}" = "$mark_pfx" ]; then
                  ${profileBin}/zellij --session "$p_zs" action undo-rename-pane --pane-id "$p_zp" 2>/dev/null || true
                fi
              done < <(printf '%s\n' "$panes" | jq -r 'to_entries[] | .key as $zs | .value[] | [$zs, (.id | tostring), .title] | @tsv')

              # --- [PROJECTIONS]
              # The zjstatus top bar is the ONE render surface; the collector owns role->palette styling (build-time hexes from the theme owner)
              # and ships fully formatted payloads the bar renders verbatim (dynamic). ONE jq over the cache snapshot renders every cell (fork
              # discipline: one projection per payload). The attention cell NAMES the waiter — "[?] SESSION·T2" (ASCII marker register, orange),
              # "[?] n · <newest>" when several wait; bells stay a count ("[B] n", amber); standing alerts ride their OWN red cell naming the
              # first kind (+N overflow), so estate state never recolors the agent cell. INVARIANT: every payload — populated or empty — opens
              # with an explicit role-derived #[bg=surface] directive; a directive-less payload under rendermode dynamic inherits the adjacent
              # cell's hue (the empty-state relic), and an empty payload would drop the pipe message entirely. The waiter label carries a foreign
              # session name, so the "#[" opener defuses here exactly as notify_bars defuses toast text.
              IFS=$'\x1f' read -r agents_cell alerts_cell sessions_n < <(jq -r '
                def seg(fg; a; t): "#[bg=${roles.surface.surface.hex},fg=" + fg + a + "]" + t;
                def blank: "#[bg=${roles.surface.surface.hex}] ";
                (.attention.needs_input // 0) as $needs
                | (.attention.latest.label // "agent" | gsub("#\\["; "[")) as $who
                | (.bells.count // 0) as $bells
                | (.alerts.count // 0) as $alerts
                | [
                    (if $needs == 0 and $bells == 0 then blank
                     else (if $needs > 0 then
                             seg("${roles.state.attention.hex}"; ",bold";
                               " ${icons.alphabet.attention.ascii} " + (if $needs > 1 then "\($needs) · " else "" end) + $who)
                           else "" end)
                          + (if $bells > 0 then seg("${roles.state.warning.hex}"; ""; " ${icons.alphabet.bell.ascii} \($bells)") else "" end)
                          + " " end),
                    (if $alerts == 0 then blank
                     else seg("${roles.state.danger.hex}"; ",bold";
                       " ${icons.alphabet.failure.ascii} \(.alerts.rows[0].kind // "alert" | ascii_upcase)"
                       + (if $alerts > 1 then " +\($alerts - 1)" else "" end) + " ") end),
                    (.sessions | length | tostring)
                  ] | join("\u001f")' "$cache")

              # Workspace-graph lane rows (forge-zellij agent-lane inventory arm): lifecycle sessions with real pane targets, no process census.
              jq -c '[.sessions[] | {lane, status: .state, pane_id: (.zellij_pane // "")}]' "$cache" >"$lanes_out.tmp.$$"
              mv "$lanes_out.tmp.$$" "$lanes_out"

              # ONE broadcast fold owns pipe delivery for cells and toasts over the tick's session snapshot; a dead server is benign.
              # __SESSION__ in a payload interpolates each session's uppercase display name — the identity chip, pink accent fill flush to
              # the bar's right edge (the trailing space rides inside the fill, so no surface gap trails it); the name is foreign text, so
              # its "#[" opener defuses before it rides a payload.
              zj_broadcast() { # $@ = zjstatus pipe payloads, one delivery per live session each
                local s chip payload
                while IFS= read -r s; do
                  [ -n "$s" ] || continue
                  chip="''${s^^}"
                  chip="''${chip//"#["/[}"
                  for payload in "$@"; do
                    ${profileBin}/zellij --session "$s" pipe "''${payload//__SESSION__/$chip}" 2>/dev/null || true
                  done
                done <<<"$live_sessions"
              }
              zj_broadcast \
                ${pipeBroadcast}

              # Rise contract per notification class: rise_gate is the predicate (count rise + per-class throttle); notify_post fans terminal-notifier
              # banner (optional subtitle + click verb), in-bar toast, ntfy publish (priority/tags; absent custody → local-only). The {notifications}
              # widget renders payloads literally, so class rides the ASCII marker prefix ("[?]" needs-input, "[X]" failure — the alphabet's ascii
              # twins) and per-urgency color stays on the cells. A new class is one gate + one post; a dead zellij, absent notifier, or unreachable
              # ntfy target is benign.
              notify_bars() { # $1 = one-line message, truncated to the toast budget and broadcast on the shared fold
                local msg
                # Foreign text (prompt bodies, pane peeks) rides these payloads: fold every control byte and defuse the "#[" opener so the
                # toast can never smuggle a terminal escape or a zjstatus directive.
                msg="$(printf '%s\n' "$1" | tr -d '[:cntrl:]')"
                msg="''${msg//"#["/[}"
                zj_broadcast "zjstatus::notify::''${msg:0:120}"
              }
              # Cross-device custody: session env first, launchd GUI replay second (the collector runs under launchd with no session env).
              ntfy_url="''${NTFY_URL:-}" ntfy_topic="''${NTFY_TOPIC:-}" ntfy_token="''${NTFY_TOKEN:-}"
              if [ -z "$ntfy_url" ] && [ -x /bin/launchctl ]; then
                ntfy_url="$(/bin/launchctl getenv NTFY_URL || true)"
                ntfy_topic="$(/bin/launchctl getenv NTFY_TOPIC || true)"
                ntfy_token="$(/bin/launchctl getenv NTFY_TOKEN || true)"
              fi
              notify_remote() { # $1=priority $2=tags $3=title $4=message
                [ -n "$ntfy_url" ] && [ -n "$ntfy_topic" ] || return 0
                local -a auth=()
                [ -z "$ntfy_token" ] || auth=(-H "Authorization: Bearer $ntfy_token")
                curl -fsS --max-time 5 -X POST "$ntfy_url/$ntfy_topic" \
                  -H "X-Title: $3" -H "X-Priority: $1" -H "X-Tags: $2" \
                  ''${auth[0]+"''${auth[@]}"} --data "$4" >/dev/null 2>&1 || true
              }
              rise_gate() { # $1=count $2=prev $3=last_epoch
                [ "''${1:-0}" -gt "''${2:-0}" ] \
                  && [ $((now - ''${3:-0})) -ge ${toString notifyPolicy.minIntervalSec} ]
              }
              notify_post() { # $1=group $2=title $3=subtitle("" = none) $4=banner_msg $5=bar_msg $6=click_cmd("" = none) $7=priority $8=tags
                if [ -n "$tn" ]; then
                  local -a tn_args=(-title "$2" -message "$4" -group "$1")
                  [ -z "$3" ] || tn_args+=(-subtitle "$3")
                  [ -z "$6" ] || tn_args+=(-execute "$6")
                  "$tn" "''${tn_args[@]}" >/dev/null 2>&1 || true
                fi
                notify_bars "$5"
                notify_remote "$7" "$8" "$2" "$4"
              }

              # needs-input rise: the banner NAMES the waiter (title "Forge · SESSION·T2"), carries the verbatim Notification prompt as the body
              # (the waiting pane's last line only as fallback), and states the reply destination in the subtitle; its click runs the policy verb —
              # `answer` (alerter reply routed into the waiting pane) where the alerter rail exists, bare `focus` elsewhere (osascript clicks
              # opened Script Editor — the scar that keeps posting on terminal-notifier).
              prev_needs="$(printf '%s\n' "$prev" | jq -r '.attention.needs_input // 0')"
              last_notify="$(printf '%s\n' "$m" | jq -r '.last_notify // 0')"
              notified=0
              tn='${tnBin}'
              if ${lib.boolToString notifyPolicy.needsInput} \
                && rise_gate "''${needs:-0}" "$prev_needs" "$last_notify"; then
                peek_line=""
                IFS=$'\x1f' read -r n_label n_zs n_zp n_msg < <(jq -r \
                  '.latest // {} | [.label // "agent", .zellij_session // "", .zellij_pane // "", .message // ""] | join("\u001f")' < <(printf '%s\n' "$att")) || true
                if [ -z "''${n_msg:-}" ] && [ -n "''${n_zs:-}" ] && [ -n "''${n_zp:-}" ]; then
                  peek_line="$(${profileBin}/forge-zellij peek --session "$n_zs" --pane "$n_zp" --lines 5 --text 2>/dev/null | tail -1 || true)"
                  peek_line="''${peek_line:0:80}"
                fi
                n_detail="''${n_msg:-$peek_line}"
                n_subtitle=""
                [ -z "''${n_zs:-}" ] || n_subtitle="reply lands in ''${n_zs} pane ''${n_zp}"
                n_count=""
                [ "''${needs:-0}" -le 1 ] || n_count="''${needs}x · "
                notify_post forge-agents "Forge · ''${n_label:-agent}" "$n_subtitle" \
                  "''${n_count}''${n_detail:-waiting for input}" \
                  "${icons.alphabet.attention.ascii} ''${n_count}''${n_label:-agent}''${n_detail:+ — $n_detail}" \
                  "${profileBin}/forge-agents ${notifyPolicy.clickVerb}" \
                  "${notifyPolicy.remote.needsInput.priority}" "${notifyPolicy.remote.needsInput.tags}"
                notified=1
              fi

              # standing-alert rise: banner in its own group, no click verb; forge-receipts --verb failures is the follow-up surface.
              prev_alerts="$(printf '%s\n' "$prev" | jq -r '.alerts.count // 0')"
              last_alert_notify="$(printf '%s\n' "$m" | jq -r '.last_alert_notify // 0')"
              alert_notified=0
              if ${lib.boolToString notifyPolicy.alerts} \
                && rise_gate "''${alerts_n:-0}" "$prev_alerts" "$last_alert_notify"; then
                alert_labels="$(printf '%s\n' "$alerts" | jq -r 'map(.label) | join(", ")')"
                notify_post forge-estate "Forge Estate" "" \
                  "''${alerts_n} standing alert(s): ''${alert_labels}" \
                  "${icons.alphabet.failure.ascii} ''${alert_labels}" "" \
                  "${notifyPolicy.remote.alerts.priority}" "${notifyPolicy.remote.alerts.tags}"
                alert_notified=1
              fi

              # --- [META_TRANSITION_RECEIPT]
              # The meta file carries only the per-class notification throttle stamps; the pane-mark set needs no persistence — displayed
              # titles are the reconcile's ground truth.
              jq -cn --argjson now "$now" --argjson m "$m" \
                --argjson notified "$notified" --argjson alert_notified "$alert_notified" '{
                  last_notify: (if $notified == 1 then $now else ($m.last_notify // 0) end),
                  last_alert_notify: (if $alert_notified == 1 then $now else ($m.last_alert_notify // 0) end)
                }' >"$meta.tmp.$$"
              mv "$meta.tmp.$$" "$meta"

              summary="needs=''${needs:-0} sessions=$sessions_n alerts=''${alerts_n:-0} bells=''${bells_n:-0}"
              prev_summary="$(printf '%s\n' "$prev" | jq -r '"needs=\(.attention.needs_input // 0) sessions=\(.sessions | length) alerts=\(.alerts.count // 0) bells=\(.bells.count // 0)"' 2>/dev/null)" || prev_summary=""
              if [ "$summary" != "$prev_summary" ] || [ "$notified" = 1 ] || [ "$alert_notified" = 1 ]; then
                printf -v receipt_row 'ts=%s\tverb=collect\tresult=ok\t%s\tnotified=%s' \
                  "$ts" "''${summary// /$'\t'}" "$notified"
                append_receipt "$receipt_row" || true
              fi
            }

            # Click-routing: the inner hop focuses the zellij pane and chases the attached client's pty; the outer hop resolves pty -> hosting app
            # through process ancestry and dispatches that app's focus row (unknown app: bare raise). Clicks run headless, so lane receipts are the
            # only witness when routing goes sideways.
            focus_receipt() {
              local row
              printf -v row 'ts=%s\tverb=focus\tlane=%s\ttty=%s\tresult=ok' \
                "$(iso_now)" "$1" "''${tty:-.}"
              append_receipt "$row" 2>/dev/null || true
            }
            # Generic resolver: the lowest pid on the pty is its session leader; walk ancestry to the first command inside an .app bundle. macOS `ps
            # -o comm=` prints full executable paths, so the bundle names the host deterministically for any terminal.
            host_app_for_tty() { # $1=tty (ttysNNN) -> app basename on stdout
              local pid cmd
              pid="$(${psBin} -t "$1" -o pid= 2>/dev/null | sort -n | head -1 | tr -d ' ')"
              while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
                cmd="$(${psBin} -o comm= -p "$pid" 2>/dev/null)"
                case "$cmd" in
                  *.app/*)
                    basename "''${cmd%%.app/*}"
                    return 0
                    ;;
                esac
                pid="$(${psBin} -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
              done
              return 1
            }
            focus_wezterm() { # $1=tty $2=recorded-pane-id — --no-auto-start on every cli call: a click on a dead GUI must never fork a mux server
              [ -n "$wezbin" ] || return 1
              local pane=""
              if [ -n "$1" ]; then
                pane="$("$wezbin" cli --no-auto-start list --format json 2>/dev/null \
                  | jq -r --arg t "/dev/$1" 'first(.[] | select(.tty_name == $t) | .pane_id) // empty' || true)"
              fi
              if [ -n "$pane" ]; then
                "$wezbin" cli --no-auto-start activate-pane --pane-id "$pane" 2>/dev/null || true
                /usr/bin/open -a WezTerm 2>/dev/null || true
                focus_receipt "wezterm-pty"
                return 0
              fi
              if [ -n "$2" ] && "$wezbin" cli --no-auto-start activate-pane --pane-id "$2" 2>/dev/null; then
                /usr/bin/open -a WezTerm 2>/dev/null || true
                focus_receipt "wezterm-pane"
                return 0
              fi
              return 1
            }
            focus_terminal() { # $1=tty (Terminal.app tab match by pty)
              [ -n "$1" ] || return 1
              local hit
              # Timeout budget: a hung Apple Event must never wedge the click.
              hit="$(/usr/bin/osascript 2>/dev/null <<OSA
      with timeout of 5 seconds
        tell application "Terminal"
          repeat with w in windows
            repeat with t in tabs of w
              if (tty of t) is "/dev/$1" then
                set selected of t to true
                set index of w to 1
                activate
                return "hit"
              end if
            end repeat
          end repeat
        end tell
      end timeout
      return ""
      OSA
              )" || hit=""
              [ "$hit" = "hit" ] || return 1
              focus_receipt "terminal-tab"
              return 0
            }
            cmd_focus() {
              local row zs zp wp tp app handler live_sessions ctty
              declare -A focus_row=([WezTerm]=focus_wezterm [Terminal]=focus_terminal)
              row="$(jq -c '.attention.latest // empty' "$cache" 2>/dev/null || true)"
              [ -n "$row" ] || row="$(tail -n 500 "$feed" 2>/dev/null \
                | jq -Rcn "$jq_defs latest_needs" 2>/dev/null || true)"
              # One projection per row snapshot; the 0x1f join survives empties.
              IFS=$'\x1f' read -r zs zp wp tp tty < <(jq -r \
                '[.zellij_session // "", .zellij_pane // "", .wezterm_pane // "", .term // "", .tty // ""] | join("\u001f")' \
                < <(printf '%s\n' "''${row:-null}") 2>/dev/null) || true
              # Feed rows are foreign material: tty crosses into ps and an AppleScript literal, so a non-pty spelling drops at the seam.
              [[ "''${tty:-}" =~ ^[A-Za-z0-9]*$ ]] || tty=""
              wezbin="/Applications/WezTerm.app/Contents/MacOS/wezterm"
              [ -x "$wezbin" ] || wezbin="$(command -v wezterm || true)"

              # Inner hop: focus the exact zellij pane, then chase the attached client's pty (reattachment moves it, so the row's tty is advisory).
              live_sessions="$(${profileBin}/zellij list-sessions -ns 2>/dev/null || true)"
              if [ -n "$zs" ] && grep -qxF "$zs" <<<"$live_sessions"; then
                [ -z "$zp" ] || ${profileBin}/zellij --session "$zs" action focus-pane-id "$zp" 2>/dev/null || true
                # $NF == s: attach clients end their argv with the session name — exact-field compare, so "a" never matches a client attached to "abc".
                ctty="$(${psBin} -axo tty=,args= | awk -v s="$zs" \
                  '$1 != "??" && $0 ~ /zellij/ && $0 !~ /--server/ && $NF == s {print $1; exit}' || true)"
                [ -z "$ctty" ] || tty="$ctty"
              fi

              # Outer hop: ancestry-resolved host app first, the recorded term program as fallback vocabulary, WezTerm as the estate default.
              app=""
              [ -z "''${tty:-}" ] || app="$(host_app_for_tty "$tty" || true)"
              if [ -z "$app" ]; then
                case "$tp" in
                  Apple_Terminal) app="Terminal" ;;
                  *) app="WezTerm" ;;
                esac
              fi
              handler="''${focus_row[$app]:-}"
              if [ -n "$handler" ] && "$handler" "''${tty:-}" "$wp"; then
                return 0
              fi
              # Bare raise honors the resolved app; a TCC-blocked tab match still lands the operator on the right application.
              /usr/bin/open -a "$app" 2>/dev/null || true
              focus_receipt "$(printf '%s-app' "$app" | tr '[:upper:]' '[:lower:]')"
            }

            # Answer channel: the needs-input banner click lands here. Resolve the latest attention row, put the VERBATIM Notification prompt in
            # front of the operator (the waiting pane's tail only when the hook captured no message), title the dialog with the waiter's name, and
            # write the typed reply back into the exact pane by pane-id — the notification answers the agent without a window switch. Every
            # degraded leg falls back to focus.
            answer_receipt() { # $1=result $2=reply_len
              local row
              printf -v row 'ts=%s\tverb=answer\treply_len=%s\tresult=%s' \
                "$(iso_now)" "$2" "$1"
              append_receipt "$row" 2>/dev/null || true
            }
            cmd_answer() {
              local alr row label zs zp msg prompt_text ans atype reply
              alr='${alerterBin}'
              row="$(jq -c '.attention.latest // empty' "$cache" 2>/dev/null || true)"
              IFS=$'\x1f' read -r label zs zp msg < <(jq -r \
                '[.label // "agent", .zellij_session // "", .zellij_pane // "", .message // ""] | join("\u001f")' \
                < <(printf '%s\n' "''${row:-null}") 2>/dev/null) || true
              if [ -z "$alr" ] || [ -z "''${zs:-}" ] || [ -z "''${zp:-}" ]; then
                cmd_focus
                return 0
              fi
              prompt_text="''${msg:-}"
              if [ -z "$prompt_text" ]; then
                prompt_text="$(${profileBin}/forge-zellij peek --session "$zs" --pane "$zp" --lines 10 --text 2>/dev/null | tail -6 || true)"
              fi
              [ -n "$prompt_text" ] || prompt_text="(waiting for input — pane content unavailable)"
              ans="$("$alr" --message "$prompt_text" --title "Forge · ''${label:-agent}" \
                --subtitle "reply lands in $zs pane $zp" --reply "Answer" \
                --timeout ${toString notifyPolicy.answerTimeoutSec} \
                --group forge-agents-answer --json 2>/dev/null || true)"
              atype="$(printf '%s\n' "$ans" | jq -r '.activationType // "none"' 2>/dev/null || true)"
              case "''${atype:-none}" in
                replied)
                  reply="$(printf '%s\n' "$ans" | jq -r '.activationValue // ""')"
                  if [ -n "$reply" ]; then
                    # Liveness gate on the reply target: the dialog blocks up to ${toString notifyPolicy.answerTimeoutSec}s and the pane can die
                    # mid-answer; a vanished pane degrades to focus instead of minting a false replied receipt for a write into the void.
                    if ${profileBin}/zellij --session "$zs" action list-panes --all --json 2>/dev/null \
                      | jq -e --arg id "$zp" 'any(.[]?; (.id | tostring) == $id)' >/dev/null 2>&1; then
                      # Pane-id-addressed write needs no focus; byte 13 submits.
                      ${profileBin}/zellij --session "$zs" action write-chars --pane-id "$zp" -- "$reply" 2>/dev/null || true
                      ${profileBin}/zellij --session "$zs" action write --pane-id "$zp" 13 2>/dev/null || true
                      answer_receipt replied "''${#reply}"
                    else
                      answer_receipt pane-gone "''${#reply}"
                    fi
                    cmd_focus
                    return 0
                  fi
                  answer_receipt empty-reply 0
                  ;;
                contentsClicked)
                  answer_receipt clicked 0
                  cmd_focus
                  return 0
                  ;;
                *) answer_receipt "''${atype:-none}" 0 ;;
              esac
            }

            case "$verb" in
              collect) cmd_collect ;;
              status) cmd_status "$@" ;;
              focus) cmd_focus ;;
              answer) cmd_answer ;;
              *) usage ;;
            esac
    '';
  };

  # Completion projections for the fleet/agent surface.
  mcpCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-mcp" ''
    #compdef forge-mcp
    _arguments \
      '1:verb:(outdated doctor drift reconcile generate roots snoop)' \
      '--notify[Notification Center on outdated pins]' \
      '--network[probe network-class rows]' \
      '--json[schema=forge-mcp/v1 receipt]'
  '';
  agentsCompletion = pkgs.writeTextDir "share/zsh/site-functions/_forge-agents" ''
    #compdef forge-agents
    _arguments \
      '1:verb:(collect status focus answer)' \
      '--json[raw collector cache]'
  '';
in {
  # Bar-pipe vocabulary: one owner for the collector->zjstatus wire — the zellij bar module derives its {pipe_*} lane and per-pipe rows from these
  # rows. Declared on this module because the collector evaluates on both hosts while the bar module rides the Darwin-gated apps import.
  options.forge.agents.statusPipes = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = statusPipes;
    readOnly = true;
    description = "Ordered zjstatus pipe-cell names the forge-agents collector feeds.";
  };

  config = {
    home.packages = launchers ++ [maghzPostgres rhinoRouter forgeMcp forgeAgents mcpCompletion agentsCompletion pkgs.mcp-nixos];

    # Each Darwin switch reasserts the fleet maps while preserving non-MCP client state; Codex app-private rows remain presence-owned by ChatGPT.
    home.activation.forgeMcpReconcile = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${forgeMcp}/bin/forge-mcp reconcile claude
      run ${forgeMcp}/bin/forge-mcp reconcile codex
    '');

    # Identity bundle rows on the shared owner (bundle-apps.nix): Login Items & Extensions resolves each agent's AssociatedBundleIdentifiers to a name.
    forge.bundleApps = {
      forge-mcp-drift = "Forge MCP Drift";
      forge-agents = "Forge Agents";
    };

    launchd.agents = {
      # Weekly pin-drift banner: Notification Center only when a pin is outdated; silent when current or offline (a registry failure never notifies).
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
      # Minute-cadence collector: cached facts for the bar cells; receipts land only on state transitions so the log stays quiet.
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
  };
}
