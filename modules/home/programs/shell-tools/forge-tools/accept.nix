# Title         : accept.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools/accept.nix
# ----------------------------------------------------------------------------
# First-switch and first-session acceptance choreography: one ordered, receipt-bearing rail from preflight through client/runtime checks, idempotent
# and re-enterable from any step (--from/--only). Probes stay owner-local (forge-doctor lenses, forge-terminal-accept, forge-mcp doctor); this
# owner orders and asserts. Key material is asserted by NAME only, never value.
{
  pkgs,
  tl,
  forgeActivationSweep,
  forgeDoctor,
  forgeRedeploy,
}: {
  forgeAccept = tl.mkTool {
    name = "forge-accept";
    inputs = [pkgs.coreutils pkgs.gnugrep pkgs.gawk pkgs.jq pkgs.findutils pkgs.zellij pkgs.flock forgeActivationSweep forgeDoctor forgeRedeploy];
    text = ''
      ${tl.statusFold}
      declare -ra STEPS=(preflight switch replay outputs doctor zellij terminal fleet lanes relaunch)
      usage() {
        printf 'Usage: forge-accept [--from STEP | --only STEP | --list]\n  steps: %s\n' "''${STEPS[*]}" >&2
        exit 64
      }
      from="" only=""
      case "''${1:-}" in
        "") ;;
        --list) printf '%s\n' "''${STEPS[@]}"; exit 0 ;;
        --from) from="''${2:?--from requires a step}" ;;
        --only) only="''${2:?--only requires a step}" ;;
        *) usage ;;
      esac
      if [ -n "$from$only" ]; then
        [[ " ''${STEPS[*]} " == *" ''${from:-$only} "* ]] || usage
      fi

      uid="$(id -u)"
      forge_root="${tl.forgeRootExpr}"
      custom_conf="/etc/nix/nix.custom.conf"
      lock_file="${tl.redeployLockExpr}"
      cache_home="''${XDG_CACHE_HOME:-$HOME/.cache}"
      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
      op_cache="$config_home/hm-op-session.sh"
      gui_manifest="$cache_home/forge-secrets/gui-replay.names"
      brew_bin="${tl.brewExpr}"
      pass=0 warn=0 fail=0 instruct=0 skip=0

      row() {
        append_receipt "$(printf 'ts=%s\tstep=%s\tstatus=%s\tdetail=%s' "$ts" "$2" "$1" "$3")" || true
        printf '%s | %-22s | %s\n' "$(mark "$1")" "$2" "$3" >&2
        case "$1" in
          PASS) pass=$((pass + 1)) ;;
          WARN) warn=$((warn + 1)) ;;
          FAIL) fail=$((fail + 1)) ;;
          INSTRUCT) instruct=$((instruct + 1)) ;;
          SKIP) skip=$((skip + 1)) ;;
        esac
      }
      key_names() {
        [ -f "$1" ] || return 0
        # No-match is a valid empty set; grep's rc=1 must not kill the rail.
        grep -oE '^export [A-Za-z_][A-Za-z0-9_]*' "$1" | awk '{print $2}' || true
      }
      # GUI-domain env NAMES only: values are stripped before anything prints; launchctl getenv false-negatives make raw print the only truthful read.
      gui_names() {
        /bin/launchctl print "gui/$uid" 2>/dev/null \
          | awk '/^\tenvironment = \{/ {f = 1; next} f && /^\t\}/ {exit} f {sub(/^\t\t/, ""); sub(/ =>.*/, ""); print}'
      }
      expected_names() {
        key_names "$op_cache" | sort -u
      }

      step_preflight() {
        if [ -f "$forge_root/flake.nix" ]; then
          row PASS preflight-flake "flake root $forge_root"
        else
          row FAIL preflight-flake "missing flake root $forge_root"
          return 0
        fi
        local casks nightly="absent" stable="absent"
        casks="$("$brew_bin" list --cask 2>/dev/null || true)"
        [[ $'\n'"$casks"$'\n' != *$'\n'wezterm@nightly$'\n'* ]] || nightly="installed"
        [[ $'\n'"$casks"$'\n' != *$'\n'wezterm$'\n'* ]] || stable="installed"
        if [ "$nightly" = "installed" ] && [ "$stable" = "absent" ]; then
          row PASS preflight-cask "wezterm@nightly=$nightly stable=$stable"
        else
          row FAIL preflight-cask "wezterm@nightly=$nightly stable=$stable; conflicts_with kills brew bundle under activation — uninstall stable first"
        fi
        if [ ! -e "$custom_conf" ] || [ -L "$custom_conf" ]; then
          row PASS preflight-customconf "$custom_conf $([ -L "$custom_conf" ] && echo symlink || echo absent)"
        else
          row FAIL preflight-customconf "real file blocks activation; forge-redeploy --switch adopts it"
        fi
        local sweep_rc=0
        forge-activation-sweep >/dev/null 2>&1 || sweep_rc=$?
        if [ "$sweep_rc" = 0 ]; then
          row PASS preflight-sweep "no root-owned in-the-way HM targets"
        else
          row FAIL preflight-sweep "rc=$sweep_rc; run forge-activation-sweep --clear before switching"
        fi
        if (
          exec {probe_fd}>"$lock_file"
          flock -n "$probe_fd"
        ) 2>/dev/null; then
          row PASS preflight-lock "deploy lock free"
        else
          row WARN preflight-lock "deploy/maintenance run holds $lock_file"
        fi
      }

      step_switch() {
        local rc=0
        forge-redeploy --switch || rc=$?
        if [ "$rc" = 0 ]; then
          row PASS switch "forge-redeploy --switch ok; system=$(readlink /run/current-system)"
        else
          row FAIL switch "forge-redeploy --switch rc=$rc; receipt in forge-redeploy.receipts.log"
        fi
      }

      step_replay() {
        /bin/launchctl kickstart -k "gui/$uid/com.parametric-forge.gui-op-secrets" 2>/dev/null || true
        sleep 3
        if [ ! -f "$gui_manifest" ]; then
          row WARN replay "no gui-replay manifest at $gui_manifest; the agent has not replayed on this generation"
          return 0
        fi
        local missing
        missing="$(comm -23 <(sort -u "$gui_manifest") <(gui_names | sort -u) | paste -sd' ' -)"
        if [ -z "$missing" ]; then
          row PASS replay "gui domain carries all $(wc -l <"$gui_manifest" | tr -d ' ') replayed key names (new spawns only; running apps keep their env)"
        else
          row FAIL replay "gui domain missing replayed names: $missing"
        fi
      }

      step_outputs() {
        # Clean-env INTERACTIVE login shell: the terminal lane. typeset -U dedup lives in .zshrc, which non-interactive login shells skip, and an
        # inherited caller PATH would fake duplicate segments.
        local path_out dup
        # shellcheck disable=SC2016  # $PATH expands inside the probed zsh, not here.
        path_out="$(env -i HOME="$HOME" USER="$USER" LOGNAME="$USER" SHELL=/bin/zsh TERM=xterm \
          /bin/zsh -il -c 'printf %s "$PATH"' 2>/dev/null || true)"
        dup="$(printf '%s\n' "$path_out" | tr ':' '\n' | grep -v '^$' | sort | uniq -d | paste -sd' ' -)"
        if [ -n "$path_out" ] && [ -z "$dup" ] && [[ "$path_out" == *"/etc/profiles/per-user/"* ]]; then
          row PASS outputs-path "login PATH single-owner: per-user profile present, no duplicate segments"
        else
          row FAIL outputs-path "dup segments: ''${dup:-none}; per-user profile $([[ "$path_out" == *"/etc/profiles/per-user/"* ]] && echo present || echo ABSENT)"
        fi
        local dumps
        dumps="$(find "$config_home/zsh" -maxdepth 1 -name '.zcompdump*' 2>/dev/null | wc -l | tr -d ' ')"
        if [ "$dumps" = 0 ]; then
          row PASS outputs-compdump "no compdump litter in ZDOTDIR"
        else
          row WARN outputs-compdump "$dumps .zcompdump file(s) in ZDOTDIR; the generated compdump path is cache-owned — remove the strays"
        fi
        local zwarn
        zwarn="$(/bin/zsh -il -c 'exit 0' 2>&1 | grep -i 'fzf' | head -1 || true)"
        if [ -z "$zwarn" ]; then
          row PASS outputs-fzf "interactive zsh emits no fzf width warnings"
        else
          row FAIL outputs-fzf "fzf warning: $zwarn"
        fi
      }

      # Machine-health lenses delegate to forge-doctor: the doctor owns the probes, this rail owns ordering and the verdict fold.
      step_doctor() {
        local l out res detail
        for l in path launchd parity; do
          out="$(forge-doctor "$l" --json 2>/dev/null || true)"
          res="$(printf '%s\n' "$out" | jq -r '.result // empty' 2>/dev/null || true)"
          detail="$(printf '%s\n' "$out" | jq -r '(.rows[-1] // {}) | to_entries | map("\(.key)=\(.value)") | join(" ")' 2>/dev/null || true)"
          case "$res" in
            ok) row PASS "doctor-$l" "''${detail:-clean}" ;;
            drift) row FAIL "doctor-$l" "''${detail:-drift}; inspect with forge-doctor $l" ;;
            *) row FAIL "doctor-$l" "forge-doctor $l emitted no envelope" ;;
          esac
        done
      }

      # Server-respawn legality: a zellij server inherits its spawner's env, so a server predating the live generation serves stale session variables.
      # Respawn is legal ONLY for forge-owned sessions with zero attached clients; user sessions get an instruction row — only WezTerm (launchd env)
      # may spawn the replacement server, never an agent shell.
      step_zellij() {
        local sys_epoch sessions name pid start attached lstart
        sys_epoch="$(stat -c %Y /run/current-system 2>/dev/null || echo 0)"
        sessions="$(zellij list-sessions -n 2>/dev/null | grep -v 'EXITED' | awk '{print $1}' || true)"
        if [ -z "$sessions" ]; then
          row PASS zellij-respawn "no live sessions; next WezTerm launch spawns fresh servers (legal respawn window)"
          return 0
        fi
        while IFS= read -r name; do
          [ -n "$name" ] || continue
          pid="$(/usr/bin/pgrep -f -- "zellij.*--server .*/''${name}\$" | head -1 || true)"
          start=0
          if [ -n "$pid" ]; then
            lstart="$(/bin/ps -o lstart= -p "$pid" 2>/dev/null || true)"
            [ -z "$lstart" ] || start="$(date -d "$lstart" +%s 2>/dev/null || echo 0)"
          fi
          attached="$(zellij --session "$name" action list-clients 2>/dev/null | tail -n +2 | wc -l | tr -d ' ' || echo 0)"
          if [ "''${start:-0}" != 0 ] && [ "$start" -ge "$sys_epoch" ]; then
            row PASS zellij-respawn "session '$name' server postdates the live generation (clients=''${attached:-0})"
          elif [[ "$name" =~ ^fa-[0-9]+-[0-9]+$ ]] && [ "''${attached:-0}" = 0 ]; then
            zellij kill-session "$name" >/dev/null 2>&1 || true
            zellij delete-session "$name" >/dev/null 2>&1 || true
            row PASS zellij-respawn "disposable '$name' (stale server) reaped; respawn legal: forge-owned, zero clients"
          else
            row INSTRUCT zellij-respawn "session '$name' server predates the live generation (clients=''${attached:-0}); close it and relaunch from WezTerm — respawn is legal only at zero attached clients, and only WezTerm may spawn the server"
          fi
        done < <(printf '%s\n' "$sessions")
      }

      step_terminal() {
        command -v forge-terminal-accept.sh >/dev/null 2>&1 || {
          row SKIP terminal "forge-terminal-accept.sh not on PATH"
          return 0
        }
        local out rc=0 p f d
        out="$(forge-terminal-accept.sh 2>/dev/null)" || rc=$?
        p="$(printf '%s\n' "$out" | jq -r '.summary.pass // 0' 2>/dev/null || echo 0)"
        f="$(printf '%s\n' "$out" | jq -r '.summary.fail // 0' 2>/dev/null || echo 0)"
        d="$(printf '%s\n' "$out" | jq -r '.summary.defer // 0' 2>/dev/null || echo 0)"
        if [ "$rc" = 0 ] && [ "''${f:-1}" = 0 ]; then
          row PASS terminal "terminal harness pass=$p defer=$d (deferred rows run in the attached leg)"
        else
          row FAIL terminal "terminal harness rc=$rc pass=$p fail=$f defer=$d"
        fi
      }

      step_fleet() {
        command -v forge-mcp >/dev/null 2>&1 || {
          row SKIP fleet-doctor "forge-mcp not on PATH"
          return 0
        }
        local out rc=0 drc=0
        out="$(forge-mcp doctor 2>&1)" || rc=$?
        if [ "$rc" = 0 ]; then
          row PASS fleet-doctor "all fleet wrappers resolve"
        else
          row FAIL fleet-doctor "failing rows: $(printf '%s\n' "$out" | { grep '^\[FAIL\]' || true; } | awk '{print $2}' | paste -sd' ' -)"
        fi
        forge-mcp drift >/dev/null 2>&1 || drc=$?
        if [ "$drc" = 0 ]; then
          row PASS fleet-drift "manifest matches both client registrations"
        else
          row FAIL fleet-drift "registration drift; run forge-mcp drift"
        fi
      }

      step_lanes() {
        local expected tui_missing gui_missing
        expected="$(expected_names)"
        [ -n "$expected" ] || {
          row WARN lanes "no op-injected session material on disk; run forge-redeploy --switch"
          return 0
        }
        tui_missing="$(ZKEYS="$(printf '%s\n' "$expected" | paste -sd' ' -)" /bin/zsh -il -c \
          'for k in ''${(s: :)ZKEYS}; do [ -n "''${(P)k}" ] || print "$k"; done' 2>/dev/null | paste -sd' ' -)"
        gui_missing="$(comm -23 <(printf '%s\n' "$expected") <(gui_names | sort -u) | paste -sd' ' -)"
        if [ -z "$tui_missing$gui_missing" ]; then
          row PASS lanes "shell/gui carry the op-injected key-name set ($(printf '%s\n' "$expected" | wc -l | tr -d ' ') names)"
        else
          row FAIL lanes "missing — shell:[''${tui_missing}] gui:[''${gui_missing}]"
        fi
      }

      step_relaunch() {
        row INSTRUCT relaunch-chords "operator: in a fresh WezTerm window, verify karabiner leader chords fire — letter chords AND shifted-punctuation binds (key-identity law)"
        row INSTRUCT relaunch-popup "operator: verify the yazi popup rail — toggle chord opens one popup, repeat chord dismisses, F1 tooltip renders"
        row INSTRUCT relaunch-ui "operator: verify fzf/atuin interactive UI and VSCode glyph render after relaunch"
      }

      mkdir -p "''${receipt_log%/*}"
      printf 'forge-accept: run ts=%s from=%s only=%s\n' "$ts" "''${from:-first}" "''${only:-all}" >&2
      started="false"
      for s in "''${STEPS[@]}"; do
        if [ -n "$only" ]; then
          [ "$s" = "$only" ] || continue
        elif [ -n "$from" ]; then
          [ "$s" = "$from" ] && started="true"
          [ "$started" = "true" ] || continue
        fi
        "step_$s"
      done
      result=ok
      [ "$fail" = 0 ] || result=fail
      persist_receipt "$(printf 'ts=%s\tsummary=pass:%s,warn:%s,fail:%s,instruct:%s,skip:%s\tresult=%s' \
        "$ts" "$pass" "$warn" "$fail" "$instruct" "$skip" "$result")"
      [ "$result" = ok ]
    '';
  };
}
