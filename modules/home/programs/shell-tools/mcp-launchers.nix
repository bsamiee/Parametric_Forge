# Title         : mcp-launchers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mcp-launchers.nix
# ----------------------------------------------------------------------------
# Data-plane owner: builds pinned pnpm launchers from mcp-fleet.nix rows and ships the MCP observability surface — `forge-mcp` emitting
# schema=forge-mcp/v1 receipts across outdated/doctor/drift/reconcile/generate/roots/snoop. Launchers exec their pinned servers directly under
# the client's stdio pipe. Launcher code never touches providers or credentials.
{
  config,
  lib,
  pkgs,
  ...
}: let
  profileBin = "/etc/profiles/per-user/${config.home.username}/bin";
  stateHome = config.xdg.stateHome;
  # Shared owner: the dual-receipt emit fold (receipts.nix) that forge-mcp folds for its schema=forge-mcp/v1 receipt surface.
  receiptsFold = import ../../../common/receipts.nix;
  # Host-OS row admission: launchers, projections, and drift all fold the same filtered fleet, so a Linux switch never builds, registers,
  # or expects a Darwin-only server.
  hostOs =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "darwin"
    else "linux";
  fleet = builtins.filter (row: builtins.elem hostOs (row.platforms or ["darwin" "linux"])) (import ./mcp-fleet.nix {inherit profileBin;});
  launcherRows = builtins.filter (r: r ? launcher) fleet;
  pnpmRows = builtins.filter (r: (r.launcher.kind or "pnpm") == "pnpm") launcherRows;
  uvRows = builtins.filter (r: lib.hasPrefix "uv" (r.launcher.kind or "pnpm")) launcherRows;
  fleetJson = pkgs.writeText "mcp-fleet.json" (builtins.toJSON fleet);

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
        ${row.launcher.ensure or ""}exec "$entry" "$@"
      '';
    };
  launchers = lib.concatMap (row: map (mkLauncher row) row.launcher.names) pnpmRows;

  # uv build lane: one ensure body per row serves the wrapper and the activation hook, materializing the pinned spec (PyPI pin or git rev)
  # into the shared XDG uv tool environment. The tool list is captured, never piped into grep -q: an early-exit grep would SIGPIPE uv under
  # pipefail and force a spurious reinstall on every launch. The needle proves the exact pin; a git row's needle is its rev-suffixed URL.
  uvSpec = row:
    if row.launcher.kind == "uv-git"
    then "${row.launcher.pkg} @ git+https://github.com/${lib.removePrefix "github:" row.launcher.upstream}@${row.launcher.version}"
    else "${row.launcher.pkg}==${row.launcher.version}";
  uvNeedle = row:
    if row.launcher.kind == "uv-git"
    then "git+https://github.com/${lib.removePrefix "github:" row.launcher.upstream}@${row.launcher.version}"
    else "${row.launcher.pkg} v${row.launcher.version} [required: ==${row.launcher.version}]";
  mkUvEnsure = row: ''
    export UV_TOOL_DIR="${config.xdg.dataHome}/uv/forge-tools"
    export UV_TOOL_BIN_DIR="${config.xdg.dataHome}/uv/forge-bin"
    export UV_CACHE_DIR="${config.xdg.cacheHome}/uv"
    export UV_PYTHON_DOWNLOADS=never
    export PATH="${pkgs.git}/bin:$PATH" # uv resolves a git spec by shelling out; activation runs without the session PATH
    mkdir -p "$UV_TOOL_DIR" "$UV_TOOL_BIN_DIR" "$UV_CACHE_DIR"
    tool_list="$(${pkgs.uv}/bin/uv tool list --show-version-specifiers 2>/dev/null || true)"
    if [ ! -x "$UV_TOOL_BIN_DIR/${row.launcher.bin}" ] || [[ "$tool_list" != *"${uvNeedle row}"* ]]; then
      ${pkgs.uv}/bin/uv tool install --force --python "${pkgs.python313}/bin/python3" ${
      lib.concatMapStrings (c: "--with ${lib.escapeShellArg c} ") (row.launcher.constraints or [])
    }${lib.escapeShellArg (uvSpec row)} >/dev/null
    fi
  '';
  mkUvLauncher = row: name:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail
      ${mkUvEnsure row}
      ${lib.concatMapStringsSep "\n" (attr: ''export PATH="${pkgs.${attr}}/bin:$PATH"'') (row.launcher.runtimePath or [])}
      exec "$UV_TOOL_BIN_DIR/${row.launcher.bin}" "$@"
    '';
  uvLaunchers = lib.concatMap (row: map (mkUvLauncher row) row.launcher.names) uvRows;
  # Rhino's package manager owns the router install; version-globbing keeps client configs stable across McNeel package updates. The router
  # runs directly under the client's stdio pipe — it spawns a Rhino host on demand, adopts a user-started session through its own slot
  # lifecycle, and exits with client stdin EOF. No supervisor, lease, or reaper governs it.
  rhinoRouter = pkgs.writeShellApplication {
    name = "rhino-mcp-router";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      base="$HOME/Library/Application Support/McNeel/Rhinoceros/packages/9.0/Rhino-MCP-Platform"
      entry="$(printf '%s\n' "$base"/*/router/osx-arm64/rhino-mcp-router | sort -V | tail -1)"
      if [ ! -x "$entry" ]; then
        echo "rhino-mcp-router: no Rhino-MCP-Platform package under $base" >&2
        exit 69
      fi
      exec "$entry" "$@"
    '';
  };
  # Agent host bootstrap: one splash-free idempotent verb brings the Rhino 9 host (BETA bundle, WIP lane) up and proves its MCP listener.
  # The vendor plug-in can load after the first document's open event, so the documented -runscript startup seam explicitly starts MCP; the
  # listener registry, never process presence alone, is the readiness boundary the router consumes.
  rhinoUp = pkgs.writeShellApplication {
    name = "forge-rhino-up";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      app="''${RHINO_WIP_APP_PATH:-/Applications/RhinoBETA.app}"
      rhino_bin="$app/Contents/MacOS/Rhinoceros"
      listeners="$HOME/Library/Application Support/McNeel/rhino-mcp/listeners"
      listener_ready() {
        local -r target_pid="$1"
        local candidate
        [ -n "$target_pid" ] || return 1
        for candidate in "$listeners/$target_pid"-*.json; do
          [ ! -f "$candidate" ] || return 0
        done
        return 1
      }
      mapfile -t pids < <(/usr/bin/pgrep -f "$rhino_bin" || true)
      pid="''${pids[0]:-}"
      if listener_ready "$pid"; then
        echo "rhino: MCP ready (pid $pid)"
        exit 0
      fi
      [ -d "$app" ] || { echo "forge-rhino-up: $app not installed" >&2; exit 69; }
      /usr/bin/open -a "$app" --args -nosplash '-runscript=_MCPStart _Enter'
      for _ in {1..60}; do
        mapfile -t pids < <(/usr/bin/pgrep -f "$rhino_bin" || true)
        pid="''${pids[0]:-}"
        if listener_ready "$pid"; then
          echo "rhino: MCP ready (pid $pid)"
          exit 0
        fi
        sleep 0.5
      done
      echo "forge-rhino-up: Rhino did not register an MCP listener within 30s" >&2
      exit 1
    '';
  };
  # Pin board: every launcher row joins engine-tagged (pkg|version|engine|upstream). `outdated` probes latest per engine; `advance` rewrites the
  # owning mcp-fleet.nix version literal behind the build gate.
  pins =
    builtins.concatStringsSep "\n"
    (map (r: "${r.launcher.pkg}|${r.launcher.version}|${r.launcher.updateEngine}|${r.launcher.upstream}") launcherRows);
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
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.git pkgs.jq pkgs.yq-go pkgs.findutils pkgs.gawk pkgs.gnugrep pkgs.flock];
    text = ''
      fleet='${fleetJson}'
      receipt_log="''${FORGE_MCP_RECEIPT_LOG:-$HOME/Library/Logs/forge-mcp.receipts.log}"
      vscode_mcp="$HOME/Library/Application Support/Code/User/mcp.json"
      usage() {
        echo "usage: forge-mcp outdated [--json] | advance [--json] | doctor [--json] | drift [--json] | reconcile <claude|codex>" >&2
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

      # Engine dispatch: latest version per updateEngine family — npm registry, PyPI JSON, or the upstream git HEAD rev. A probe failure returns
      # non-zero and the caller reports unknown, never drift.
      latest_for() { # $1=pkg $2=engine $3=upstream
        case "$2" in
          npm-registry) curl -fsS --max-time 20 "https://registry.npmjs.org/$(jq -rn --arg p "$1" '$p|@uri')/latest" | jq -er .version ;;
          pypi) curl -fsS --max-time 20 "https://pypi.org/pypi/$1/json" | jq -er .info.version ;;
          git-head) git ls-remote "https://github.com/''${3#github:}" HEAD 2>/dev/null | awk 'NR == 1 {print $1; exit}' | grep . ;;
          *) return 1 ;;
        esac
      }

      # Shared pin sweep: one TSV row per launcher pin (state, pkg, pinned, latest, engine); outdated presents it, advance consumes it.
      pin_rows() {
        while IFS="|" read -r pkg version engine upstream; do
          [ -n "$pkg" ] || continue
          if latest="$(latest_for "$pkg" "$engine" "$upstream")"; then
            if [ "$latest" != "$version" ]; then
              printf 'OUTDATED\t%s\t%s\t%s\t%s\n' "$pkg" "$version" "$latest" "$engine"
            else
              printf 'current\t%s\t%s\t%s\t%s\n' "$pkg" "$version" "$latest" "$engine"
            fi
          else
            printf 'unknown\t%s\t%s\t-\t%s\n' "$pkg" "$version" "$engine"
          fi
        done < <(printf '%s\n' '${pins}')
      }

      cmd_outdated() {
        as_json=0
        for a in "$@"; do
          case "$a" in
            --json) as_json=1 ;;
            *) usage ;;
          esac
        done
        rows="$(pin_rows)"
        rc=0
        ! grep -q $'^OUTDATED\t' < <(printf '%s\n' "$rows") || rc=1
        n="$(printf '%s\n' "$rows" | grep -c $'^OUTDATED\t' || true)"
        if [ "$as_json" = 1 ]; then
          jq -Rcs --arg ts "$(iso_now)" --arg rc "$rc" '{
            schema: "forge-mcp/v1", ts: $ts, verb: "outdated",
            result: (if $rc == "0" then "ok" else "outdated" end),
            rows: (split("\n") | map(select(length > 0) | split("\t")
                   | {state: .[0], pkg: .[1], pin_current: .[2], latest: .[3], engine: .[4]}))
          }' < <(printf '%s\n' "$rows")
        else
          printf '%s\n' "$rows" | while IFS=$'\t' read -r s p v l e; do
            printf '%-9s %-32s engine=%-12s pinned=%s latest=%s\n' "$s" "$p" "$e" "$v" "$l"
          done
        fi
        receipt outdated "$([ "$rc" = 0 ] && echo ok || echo outdated)" "outdated=$n"
        exit "$rc"
      }

      # Currency landing rail: rewrite each outdated pin's version literal in the fleet manifest, prove the result through the deploy owner's
      # build, then auto-commit (full automation, no branches, never an unattended switch). An unproven bump
      # is withdrawn whole, so HEAD's manifest stays last known-good.
      cmd_advance() {
        as_json=0
        for a in "$@"; do
          case "$a" in
            --json) as_json=1 ;;
            *) usage ;;
          esac
        done
        forge_root="''${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}"
        rel="modules/home/programs/shell-tools/mcp-fleet.nix"
        fleet_file="$forge_root/$rel"
        [ -f "$fleet_file" ] || {
          receipt advance fail "missing-manifest"
          echo "forge-mcp advance: missing $fleet_file" >&2
          exit 1
        }
        exec {advance_fd}>"''${XDG_CACHE_HOME:-$HOME/.cache}/forge-mcp-advance.lock"
        flock -n "$advance_fd" || {
          receipt advance skipped "lock-held"
          echo "forge-mcp advance: another advance run holds the lock; skipped" >&2
          exit 75
        }
        # Bump only an untouched manifest: uncommitted operator edits must never be entangled with an automated pin commit.
        if [ -n "$(git -C "$forge_root" status --porcelain -- "$rel")" ]; then
          receipt advance skipped "dirty-manifest"
          echo "forge-mcp advance: $rel carries uncommitted edits; skipped" >&2
          exit 75
        fi
        moved="" bumped=""
        while IFS=$'\t' read -r state pkg version latest engine; do
          [ "$state" = "OUTDATED" ] || continue
          # pkg-context rewrite: the pkg line arms the substitution and the row's own version line (always next in the launcher block) consumes it.
          awk -v pkg="$pkg" -v new="$latest" '
            index($0, "pkg = \"" pkg "\";") {hot = 1}
            hot && /version = "/ {sub(/version = "[^"]*"/, "version = \"" new "\""); hot = 0}
            {print}
          ' "$fleet_file" >"$fleet_file.advance"
          mv "$fleet_file.advance" "$fleet_file"
          moved="$moved $pkg:$version->$latest"
          bumped="''${bumped:+$bumped,}$pkg"
        done < <(pin_rows)
        if [ -z "$moved" ]; then
          receipt advance ok "current"
          [ "$as_json" = 1 ] && jq -cn --arg ts "$(iso_now)" '{schema: "forge-mcp/v1", ts: $ts, verb: "advance", result: "current", moved: []}' \
            || echo "forge-mcp advance: every pin current"
          return 0
        fi
        if "${profileBin}/forge-redeploy" --build >&2; then
          if git -C "$forge_root" -c commit.gpgsign=false commit -m "home: advance mcp pins ($bumped)" -- "$rel" >/dev/null; then
            receipt advance ok "moved=$bumped"
            [ "$as_json" = 1 ] && jq -cn --arg ts "$(iso_now)" --arg moved "$moved" \
              '{schema: "forge-mcp/v1", ts: $ts, verb: "advance", result: "landed", moved: ($moved | split(" ") | map(select(length > 0)))}' \
              || echo "forge-mcp advance: landed$moved (switch lands it: forge-redeploy --switch)"
            return 0
          fi
          receipt advance fail "commit-failed"
          echo "forge-mcp advance: bump built but commit failed; $rel left uncommitted" >&2
          exit 1
        fi
        git -C "$forge_root" checkout -- "$rel"
        receipt advance fail "build-failed moved=$bumped"
        echo "forge-mcp advance: build failed; bump withdrawn ($bumped)" >&2
        exit 1
      }

      # Named check families: launcher rows declaring `doctor` get local companion checks — the Forge launcher name IS the row.
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
          _FORGE_MCP_DOCTOR_DEADLINE=1 exec timeout -k 5 60 "$0" doctor "$@"
        fi
        as_json=0
        for a in "$@"; do
          case "$a" in
            --json) as_json=1 ;;
            *) usage ;;
          esac
        done
        tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
        rows="$tmp/rows"; : >"$rows"
        # Wrapper roll-call: every declared fleet wrapper resolves on PATH; stateless clients own protocol health.
        while IFS= read -r w; do
          if command -v "$w" >/dev/null 2>&1; then
            printf 'OK\t%s\twrapper resolves\n' "$w" >>"$rows"
          else
            printf 'FAIL\t%s\twrapper absent from PATH\n' "$w" >>"$rows"
          fi
        done < <(jq -r '.[] | (.launcher.names // [])[]' "$fleet")
        family_rows "$rows"
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
        advance) cmd_advance "$@" ;;
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
      '1:verb:(outdated advance doctor drift reconcile generate roots snoop)' \
      '--json[schema=forge-mcp/v1 receipt]'
  '';
in {
  config = {
    home.packages = launchers ++ uvLaunchers ++ [rhinoRouter rhinoUp forgeMcp mcpCompletion pkgs.mcp-nixos];

    home.activation = {
      # Warm every uv tool environment at switch so a cold client spawn never pays the install.
      ensureUvMcpTools = lib.hm.dag.entryAfter ["linkGeneration"] (lib.concatMapStringsSep "\n" mkUvEnsure uvRows);

      # Each switch on either OS reasserts the host-filtered fleet maps while preserving non-MCP client state; Codex app-private rows remain
      # presence-owned by ChatGPT.
      forgeMcpReconcile = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${forgeMcp}/bin/forge-mcp reconcile claude
        run ${forgeMcp}/bin/forge-mcp reconcile codex
      '';
    };

    # Daily currency cadence; the advance verb owns its own lock, dirty-manifest guard, build gate, and auto-commit.
    # Repo mutation is a Darwin operator-machine concern — the NixOS host holds no working tree.
    launchd.agents.forge-mcp-advance = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        Label = "com.parametric-forge.forge-mcp-advance";
        ProgramArguments = ["${forgeMcp}/bin/forge-mcp" "advance"];
        ProcessType = "Background";
        StartCalendarInterval = [
          {
            Hour = 10;
            Minute = 30;
          }
        ];
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-mcp-advance.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-mcp-advance.log";
        AssociatedBundleIdentifiers = ["com.parametric-forge.forge-nix-automation"];
      };
    };
  };
}
