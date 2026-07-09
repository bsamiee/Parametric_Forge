# Title         : forge-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools.nix
# ----------------------------------------------------------------------------
# Agent-safe Forge maintenance entrypoints.
{
  config,
  pkgs,
  ...
}: let
  forgeRedeploy = pkgs.writeShellApplication {
    name = "forge-redeploy";
    # No pkgs.nix: the Determinate profile is force-prepended below so every
    # nix/nix-env call (incl. nh's) resolves the daemon-matched client.
    runtimeInputs = [pkgs.coreutils pkgs.gawk pkgs.git pkgs.nh pkgs.nix-output-monitor pkgs.dix pkgs.nvd pkgs.cachix pkgs.flock];
    text = ''
      export PATH="/nix/var/nix/profiles/default/bin:$PATH"

      mode="check"
      gen=""
      case "''${1:-}" in
        --check-only | "")
          mode="check"
          ;;
        --build)
          mode="build"
          ;;
        --switch)
          mode="switch"
          ;;
        --rollback)
          mode="rollback"
          gen="''${2:-}"
          if [ -n "$gen" ] && ! [[ "$gen" =~ ^[0-9]+$ ]]; then
            printf 'forge-redeploy: --rollback takes an optional generation number, got: %s\n' "$gen" >&2
            exit 2
          fi
          ;;
        --generations)
          mode="generations"
          ;;
        --help | -h)
          printf 'Usage: forge-redeploy [--check-only|--build|--switch|--rollback [gen]|--generations]\n'
          exit 0
          ;;
        *)
          printf 'forge-redeploy: unknown argument: %s\n' "$1" >&2
          exit 2
          ;;
      esac

      forge_root="''${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}"
      host="''${FORGE_DARWIN_HOST:-macbook}"
      cache="''${CACHIX_CACHE:-bsamiee}"
      secrets_file="''${FORGE_SECRETS_FILE:-''${XDG_CONFIG_HOME:-$HOME/.config}/hm-op-session.sh}"
      receipt_log="''${FORGE_RECEIPT_LOG:-$HOME/Library/Logs/forge-redeploy.receipts.log}"
      lock_file="''${FORGE_REDEPLOY_LOCK:-$HOME/.cache/forge-redeploy.lock}"
      custom_conf="/etc/nix/nix.custom.conf"
      profile="/nix/var/nix/profiles/system"
      nix_env="/nix/var/nix/profiles/default/bin/nix-env"
      rebuild="/run/current-system/sw/bin/darwin-rebuild"

      # Modes take no trailing arguments; --rollback takes at most one.
      limit=1
      [ "$mode" != "rollback" ] || limit=2
      if [ "$#" -gt "$limit" ]; then
        printf 'forge-redeploy: unexpected arguments after %s\n' "$1" >&2
        exit 2
      fi

      # Generation listing is a pure read; no lock, no receipt, no flake needed.
      if [ "$mode" = "generations" ]; then
        sudo -n "$rebuild" --list-generations || {
          printf 'forge-redeploy: listing denied; run once: sudo %s --list-generations\n' "$rebuild" >&2
          exit 1
        }
        exit 0
      fi

      # One flock serializes deploys, rollbacks, and the maintenance agent.
      mkdir -p "$(dirname "$lock_file")"
      exec 9>"$lock_file"
      flock -n 9 || {
        printf 'forge-redeploy: another deploy/maintenance run holds %s\n' "$lock_file" >&2
        exit 75
      }

      # One typed receipt per state-touching run; the EXIT trap emits it even
      # when a phase aborts, so failed activations stay visible (result=fail).
      ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      system_path="-" gen_live="-"
      eval_s="-" build_s="-" activate_s="-"
      to_build="-" to_fetch="-" diff_lines="-"
      push="-" verify="-" kickstart="-" current="-"
      mux="''${ZELLIJ_SESSION_NAME:+zellij}"
      result="fail"
      emit_receipt() {
        line="$(printf 'ts=%s\tmode=%s\thost=%s\tsystem=%s\tgen=%s\teval_s=%s\tbuild_s=%s\tactivate_s=%s\tto_build=%s\tto_fetch=%s\tdiff_lines=%s\tpush=%s\tverify=%s\tkickstart=%s\tcurrent=%s\tmux=%s\tresult=%s' \
          "$ts" "$mode" "$host" "$system_path" "$gen_live" "$eval_s" "$build_s" "$activate_s" \
          "$to_build" "$to_fetch" "$diff_lines" "$push" "$verify" "$kickstart" \
          "$current" "''${mux:-none}" "$result")"
        # An unwritable log must never fail the trap or mask a landed deploy.
        { mkdir -p "$(dirname "$receipt_log")" && printf '%s\n' "$line" >>"$receipt_log"; } \
          || printf 'forge-redeploy: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
        printf 'forge-redeploy: receipt\t%s\n' "$line"
      }

      tmpdir="$(mktemp -d "''${TMPDIR:-/tmp}/forge-redeploy.XXXXXX")"
      trap 'emit_receipt; rm -rf "$tmpdir"' EXIT
      out_link="$tmpdir/system"

      # Token via single env indirection: ambient CACHIX_AUTH_TOKEN wins, secrets file
      # (FORGE_SECRETS_FILE) is the fallback, absence degrades to a skipped push.
      # A present-but-bad token never fails an already-built/switched deploy.
      push_cache() {
        if [ -z "''${CACHIX_AUTH_TOKEN:-}" ] && [ -f "$secrets_file" ]; then
          # shellcheck source=/dev/null
          . "$secrets_file" || true
        fi
        if [ -z "''${CACHIX_AUTH_TOKEN:-}" ]; then
          push="skipped" verify="skipped"
          printf 'forge-redeploy: cache push skipped: CACHIX_AUTH_TOKEN unset\n' >&2
          return 0
        fi
        if cachix push "$cache" "$1"; then
          push="ok"
          # Narinfo round-trip proves the closure is servable, not just sent.
          # negative-ttl 0: the dry-run proof phase caches a pre-push miss for
          # this exact path; an unexpired entry would fake verify=missing.
          if nix path-info --store "https://$cache.cachix.org" --narinfo-cache-negative-ttl 0 "$1" >/dev/null 2>&1; then
            verify="ok"
          else
            verify="missing"
            printf 'forge-redeploy: WARNING pushed but narinfo missing at %s.cachix.org\n' "$cache" >&2
          fi
        else
          push="failed" verify="skipped"
          printf 'forge-redeploy: WARNING cache push failed (token/network); deploy unaffected\n' >&2
        fi
      }

      run_kickstart() {
        # Daemon-side settings (trusted-users, caches) go live only after restart.
        if sudo -n /bin/launchctl kickstart -k system/systems.determinate.nix-daemon; then
          kickstart="ok"
        else
          kickstart="failed"
          printf 'forge-redeploy: WARNING daemon kickstart failed; daemon-side settings stay dormant until restart\n' >&2
        fi
      }

      # Single owner of the post-activation contract: generation capture,
      # live-system equality, then the daemon kickstart. $1 = expected store
      # path, $2 = its label.
      assert_live() {
        gen_live="$(readlink "$profile" 2>/dev/null)" || gen_live="-"
        gen_live="''${gen_live##*system-}"
        gen_live="''${gen_live%-link}"
        if [ "$(readlink /run/current-system)" != "$1" ]; then
          current="mismatch"
          printf 'forge-redeploy: FATAL live system %s != %s %s\n' "$(readlink /run/current-system)" "$2" "$1" >&2
          exit 1
        fi
        current="match"
        run_kickstart
      }

      # Activation's /etc collision guard exits 2 on an installer-written real
      # file; one adoption owner covers both switch and rollback activations.
      adopt_custom_conf() {
        { [ -f "$custom_conf" ] && [ ! -L "$custom_conf" ]; } || return 0
        sudo -n /bin/mv "$custom_conf" "$custom_conf.before-determinate-module" || {
          printf 'forge-redeploy: %s is a real file and blocks activation.\n' "$custom_conf" >&2
          printf 'forge-redeploy: run once: sudo mv %s %s.before-determinate-module\n' "$custom_conf" "$custom_conf" >&2
          exit 1
        }
      }

      # Rollback reactivates a prior generation; no flake, no build, no push.
      if [ "$mode" = "rollback" ]; then
        adopt_custom_conf
        verb=(--rollback)
        [ -z "$gen" ] || verb=(--switch-generation "$gen")
        t0=$EPOCHSECONDS
        sudo -n "$rebuild" "''${verb[@]}" || {
          activate_s=$((EPOCHSECONDS - t0))
          printf 'forge-redeploy: rollback failed; if sudo denied, run once: sudo %s %s\n' "$rebuild" "''${verb[*]}" >&2
          exit 1
        }
        activate_s=$((EPOCHSECONDS - t0))
        system_path="$(readlink /run/current-system)"
        assert_live "$(cat "$profile/systemConfig")" "rolled-back profile"
        result="ok"
        printf 'forge-redeploy: rollback ok system=%s\n' "$system_path"
        exit 0
      fi

      [ -f "$forge_root/flake.nix" ] || {
        printf 'forge-redeploy: missing flake root: %s\n' "$forge_root" >&2
        exit 1
      }
      cd "$forge_root"

      printf 'forge-redeploy: nix=%s\n' "$(command -v nix)"
      t0=$EPOCHSECONDS
      nix flake check --print-build-logs

      # Pre-build proof: to-build/to-fetch counts expose derivation-identity
      # drift (the 1h local-rebuild class) the day it appears. Parsing is
      # version-sensitive and degrades to unknown, never fails the deploy.
      if nix build --dry-run --no-link "$forge_root#darwinConfigurations.$host.system" 2>"$tmpdir/dryrun"; then
        # Store paths outside a recognized section mean the wording drifted:
        # report unknown instead of a false-clean 0/0.
        read -r to_build to_fetch < <(awk '
          /will be built:?$/ { s = 1; next }
          /will be fetched/  { s = 2; next }
          /^  \/nix\/store\// { if (s == 1) b++; else if (s == 2) f++; else u++ }
          END { if (u) print "unknown unknown"; else printf "%d %d\n", b, f }' "$tmpdir/dryrun")
      else
        to_build="unknown" to_fetch="unknown"
        printf 'forge-redeploy: WARNING dry-run failed; build counts unknown\n' >&2
      fi
      eval_s=$((EPOCHSECONDS - t0))

      # Every mode builds the toplevel through nh and reviews the closure diff.
      t0=$EPOCHSECONDS
      nh darwin build --hostname "$host" --out-link "$out_link" --diff never "$forge_root"
      build_s=$((EPOCHSECONDS - t0))
      system_path="$(readlink -f "$out_link")"

      if [ -e /run/current-system ]; then
        { dix /run/current-system "$system_path" || nvd diff /run/current-system "$system_path" || true; } | tee "$tmpdir/diff"
        diff_lines="$(wc -l <"$tmpdir/diff" | tr -d ' ')"
      else
        diff_lines=0
      fi

      case "$mode" in
        check)
          result="ok"
          printf 'forge-redeploy: check-only ok system=%s\n' "$system_path"
          ;;
        build)
          push_cache "$system_path"
          result="ok"
          printf 'forge-redeploy: build ok system=%s\n' "$system_path"
          ;;
        switch)
          adopt_custom_conf
          # Exact-closure activation: the reviewed store path is registered and
          # activated directly -- no second evaluation that could drift.
          t0=$EPOCHSECONDS
          sudo -n "$nix_env" -p "$profile" --set "$system_path" || {
            activate_s=$((EPOCHSECONDS - t0))
            printf 'forge-redeploy: profile registration denied; sudoers rows land on first switch.\n' >&2
            printf 'forge-redeploy: run once: sudo %s -p %s --set %s && sudo %s/sw/bin/darwin-rebuild activate\n' \
              "$nix_env" "$profile" "$system_path" "$system_path" >&2
            exit 1
          }
          sudo -n "$system_path/sw/bin/darwin-rebuild" activate || {
            activate_s=$((EPOCHSECONDS - t0))
            printf 'forge-redeploy: FATAL activation failed; if sudo denied, run once: sudo %s/sw/bin/darwin-rebuild activate\n' "$system_path" >&2
            exit 1
          }
          activate_s=$((EPOCHSECONDS - t0))
          # Post-activation steps degrade to warnings: the deploy already landed.
          # Push precedes the kickstart so it never races the daemon restart.
          push_cache "$system_path"
          assert_live "$system_path" "built"
          result="ok"
          printf 'forge-redeploy: switch ok system=%s\n' "$system_path"
          ;;
      esac
    '';
  };

  # Scheduled lifecycle owner for what determinate-nixd does not schedule:
  # generation retention and store optimise; background GC stays daemon-owned.
  forgeNixMaintenance = pkgs.writeShellApplication {
    name = "forge-nix-maintenance";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep pkgs.flock];
    text = ''
      export PATH="/nix/var/nix/profiles/default/bin:$PATH"

      # Reject unknown argv up front: a typo must never silently run as a
      # manual pass (600s lock wait, no AC gate).
      case "''${1:-}" in
        "") mode="manual" ;;
        --scheduled) mode="scheduled" ;;
        *)
          printf 'Usage: forge-nix-maintenance [--scheduled]\n' >&2
          exit 2
          ;;
      esac
      if [ "$#" -gt 1 ]; then
        printf 'forge-nix-maintenance: unexpected arguments after %s\n' "$1" >&2
        exit 2
      fi
      lock_file="''${FORGE_REDEPLOY_LOCK:-$HOME/.cache/forge-redeploy.lock}"
      receipt_log="''${FORGE_MAINTENANCE_RECEIPT_LOG:-$HOME/Library/Logs/forge-nix-maintenance.receipts.log}"
      nix_env="/nix/var/nix/profiles/default/bin/nix-env"

      # One typed receipt per run; the EXIT trap emits it even when a phase
      # aborts, so denied trims and failed GC stay visible (result=fail).
      ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      power="-" lock="-" trim="-" gc="-" optimise="-"
      gc_s="-" optimise_s="-"
      result="fail"
      emit_receipt() {
        line="$(printf 'ts=%s\tmode=%s\tpower=%s\tlock=%s\ttrim=%s\tgc=%s\tgc_s=%s\toptimise=%s\toptimise_s=%s\tresult=%s' \
          "$ts" "$mode" "$power" "$lock" "$trim" "$gc" "$gc_s" "$optimise" "$optimise_s" "$result")"
        # An unwritable log must never fail the trap or mask a finished run.
        { mkdir -p "$(dirname "$receipt_log")" && printf '%s\n' "$line" >>"$receipt_log"; } \
          || printf 'forge-nix-maintenance: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
        printf 'forge-nix-maintenance: receipt\t%s\n' "$line"
      }
      trap emit_receipt EXIT

      # Scheduled runs stay AC-gated and yield to a live deploy; manual runs wait.
      # No grep -q: consuming all input avoids the pipefail/SIGPIPE false skip.
      if [ "$mode" = "scheduled" ]; then
        /usr/bin/pmset -g batt | grep "AC Power" >/dev/null || {
          power="battery" result="skipped"
          exit 0
        }
        power="ac"
        flock_args=(-n)
      else
        flock_args=(-w 600)
      fi
      mkdir -p "$(dirname "$lock_file")"
      exec 9>"$lock_file"
      flock "''${flock_args[@]}" 9 || {
        lock="held" result="skipped"
        printf 'forge-nix-maintenance: deploy in flight holds %s; skipped\n' "$lock_file" >&2
        exit 75
      }
      lock="ok"

      # System generations: keep the newest five for the rollback window; the
      # NOPASSWD row pins these exact args, so a denial signals policy drift.
      trim="ok"
      sudo -n "$nix_env" -p /nix/var/nix/profiles/system --delete-generations +5 || {
        trim="denied"
        printf 'forge-nix-maintenance: WARNING system generation trim denied; rerun after a switch lands the sudoers row\n' >&2
      }
      # User profiles: drop stale generations and collect what they unpinned;
      # continuous free-space GC stays determinate-nixd-owned.
      t0=$EPOCHSECONDS
      nix-collect-garbage --delete-older-than 14d
      gc="ok" gc_s=$((EPOCHSECONDS - t0))
      t0=$EPOCHSECONDS
      nix store optimise
      optimise="ok" optimise_s=$((EPOCHSECONDS - t0))
      result="ok"
      [ "$trim" = "ok" ] || result="partial"
    '';
  };

  # Cleanup row registry: HOME-relative targets, one row per litter class.
  # mode rows converge a directory mode; path rows trash a whole residue tree;
  # glob rows trash pattern matches under a root. cargo/rustup rows carry the
  # closed retirement decision: the toolchains are retired, regrowth is litter.
  cleanupRows = pkgs.writeText "forge-cleanup-rows.json" (builtins.toJSON [
    {
      name = "launchagents-mode";
      kind = "mode";
      target = "Library/LaunchAgents";
      expect = "700";
    }
    {
      name = "zdotdir-compdump";
      kind = "glob";
      root = ".config/zsh";
      pattern = ".zcompdump*";
    }
    {
      name = "mcp-stage-litter";
      kind = "glob";
      root = ".cache/forge-mcp";
      pattern = ".stage.*";
    }
    {
      name = "pyenv-residue";
      kind = "path";
      target = ".pyenv";
    }
    {
      name = "cargo-residue";
      kind = "path";
      target = ".cargo";
    }
    {
      name = "rustup-residue";
      kind = "path";
      target = ".rustup";
    }
  ]);

  # Guarded cleanup rail: `plan` emits a durable precheck receipt, `apply`
  # executes only rows the plan proved safe, re-verified at act time and
  # trash-first, so every deletion stays recoverable from ~/.Trash.
  forgeCleanup = pkgs.writeShellApplication {
    name = "forge-cleanup";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.gawk pkgs.jq];
    text = ''
      rows_json='${cleanupRows}'
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/forge-cleanup"
      run_ts="$(date -u +%Y%m%dT%H%M%SZ)"
      usage() { echo "usage: forge-cleanup plan | apply [plan-file]" >&2; exit 64; }
      verb="''${1:-}"; shift || true

      # One detector owns every row kind; plan and apply both consume it, so
      # apply never acts on a state the detector cannot reproduce live.
      detect_row() {
        local row="$1" name kind state count kb action safe detail target expect root pattern current
        name="$(jq -r '.name' <<<"$row")"
        kind="$(jq -r '.kind' <<<"$row")"
        state=clean count=0 kb=0 action=none safe=true detail=-
        case "$kind" in
          mode)
            target="$HOME/$(jq -r '.target' <<<"$row")"
            expect="$(jq -r '.expect' <<<"$row")"
            if [ ! -d "$target" ]; then
              state=missing safe=false detail="target absent"
            else
              current="$(stat -c '%a' "$target")"
              if [ "$current" != "$expect" ]; then
                state=litter action="chmod-$expect" count=1 detail="mode=$current"
              fi
            fi
            ;;
          path)
            target="$HOME/$(jq -r '.target' <<<"$row")"
            if [ -L "$target" ]; then
              state=review safe=false detail="symlink, not a residue tree"
            elif [ -e "$target" ]; then
              state=litter action=trash count=1
              kb="$(du -sk "$target" 2>/dev/null | cut -f1 || echo 0)"
            fi
            ;;
          glob)
            root="$HOME/$(jq -r '.root' <<<"$row")"
            pattern="$(jq -r '.pattern' <<<"$row")"
            if [ -d "$root" ]; then
              count="$(find "$root" -name "$pattern" -prune -print 2>/dev/null | wc -l | tr -d ' ')"
              if [ "$count" -gt 0 ]; then
                state=litter action=trash
                kb="$(find "$root" -name "$pattern" -prune -print0 2>/dev/null | xargs -0 du -sk 2>/dev/null | awk '{s += $1} END {print s + 0}')"
              fi
            fi
            ;;
        esac
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$kind" "$state" "$count" "$kb" "$action" "$safe" "$detail"
      }

      trash() {
        mkdir -p "$HOME/.Trash"
        mv -n "$1" "$HOME/.Trash/$(basename "$1").forge-cleanup.$run_ts"
      }

      cmd_plan() {
        mkdir -p "$state_dir"
        plan_file="$state_dir/plan-$run_ts.tsv"
        {
          printf '# forge-cleanup plan\tts=%s\thome=%s\n' "$run_ts" "$HOME"
          printf '# name\tkind\tstate\tcount\tkb\taction\tsafe\tdetail\n'
          while IFS= read -r row; do detect_row "$row"; done < <(jq -c '.[]' "$rows_json")
        } | tee "$plan_file"
        printf 'forge-cleanup: plan receipt %s\n' "$plan_file"
      }

      cmd_apply() {
        plan_file="''${1:-$(find "$state_dir" -maxdepth 1 -name 'plan-*.tsv' 2>/dev/null | sort | tail -1)}"
        if [ -z "$plan_file" ] || [ ! -f "$plan_file" ]; then
          echo "forge-cleanup: no plan receipt; run forge-cleanup plan first" >&2
          exit 66
        fi
        apply_file="$state_dir/apply-$run_ts.tsv"
        {
          printf '# forge-cleanup apply\tts=%s\tplan=%s\n' "$run_ts" "$plan_file"
          while IFS=$'\t' read -r name _kind state _count _kb action safe _detail; do
            case "$name" in '#'* | "") continue ;; esac
            if [ "$safe" != true ] || [ "$state" != litter ]; then
              printf '%s\taction=none\toutcome=skipped-%s\n' "$name" "$state"
              continue
            fi
            row="$(jq -c --arg n "$name" '.[] | select(.name == $n)' "$rows_json")"
            # Re-verify at act time: a row that drifted since plan is skipped.
            fresh_state="$(detect_row "$row" | cut -f3)"
            if [ "$fresh_state" != litter ]; then
              printf '%s\taction=none\toutcome=drifted-%s\n' "$name" "$fresh_state"
              continue
            fi
            case "$action" in
              chmod-*)
                chmod "''${action#chmod-}" "$HOME/$(jq -r '.target' <<<"$row")"
                printf '%s\taction=%s\toutcome=applied\n' "$name" "$action"
                ;;
              trash)
                if [ "$(jq -r '.kind' <<<"$row")" = path ]; then
                  trash "$HOME/$(jq -r '.target' <<<"$row")"
                  printf '%s\taction=trash\toutcome=applied\tcount=1\n' "$name"
                else
                  moved=0
                  while IFS= read -r -d "" match; do
                    trash "$match"
                    moved=$((moved + 1))
                  done < <(find "$HOME/$(jq -r '.root' <<<"$row")" -name "$(jq -r '.pattern' <<<"$row")" -prune -print0 2>/dev/null)
                  printf '%s\taction=trash\toutcome=applied\tcount=%s\n' "$name" "$moved"
                fi
                ;;
              *)
                printf '%s\taction=%s\toutcome=unknown-action\n' "$name" "$action"
                ;;
            esac
          done <"$plan_file"
        } | tee "$apply_file"
        printf 'forge-cleanup: apply receipt %s\n' "$apply_file"
      }

      case "$verb" in
        plan) cmd_plan ;;
        apply) cmd_apply "$@" ;;
        *) usage ;;
      esac
    '';
  };

  # Daily currency rail: flake-input bump plus declared-vs-deployed detection.
  # Builds run through forge-redeploy --build, so receipts, flock, and cache
  # push stay single-owner; a landed bump auto-commits (operator ruling: full
  # automation, no branches) and never switches unattended.
  forgeNixDrift = pkgs.writeShellApplication {
    name = "forge-nix-drift";
    runtimeInputs = [pkgs.coreutils pkgs.git pkgs.jq pkgs.gnugrep pkgs.gawk pkgs.flock forgeRedeploy];
    text = ''
      export PATH="/nix/var/nix/profiles/default/bin:$PATH"

      case "''${1:-}" in
        "") mode="manual" ;;
        --scheduled) mode="scheduled" ;;
        *)
          printf 'Usage: forge-nix-drift [--scheduled]\n' >&2
          exit 2
          ;;
      esac
      if [ "$#" -gt 1 ]; then
        printf 'forge-nix-drift: unexpected arguments after %s\n' "$1" >&2
        exit 2
      fi

      forge_root="''${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}"
      receipt_log="''${FORGE_DRIFT_RECEIPT_LOG:-$HOME/Library/Logs/forge-nix-drift.receipts.log}"
      lock_file="''${FORGE_NIX_DRIFT_LOCK:-$HOME/.cache/forge-nix-drift.lock}"

      # One typed receipt per run; the EXIT trap emits it even when a phase
      # aborts, so failed bumps and builds stay visible (result=fail).
      ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      power="-" lock="-" worktree="-" inputs="-" bump="-"
      build="-" commit="-" deployed="-" nixd="-"
      result="fail"
      emit_receipt() {
        line="$(printf 'ts=%s\tmode=%s\tpower=%s\tlock=%s\tworktree=%s\tinputs=%s\tbump=%s\tbuild=%s\tcommit=%s\tdeployed=%s\tnixd=%s\tresult=%s' \
          "$ts" "$mode" "$power" "$lock" "$worktree" "$inputs" "$bump" \
          "$build" "$commit" "$deployed" "$nixd" "$result")"
        # An unwritable log must never fail the trap or mask a finished run.
        { mkdir -p "$(dirname "$receipt_log")" && printf '%s\n' "$line" >>"$receipt_log"; } \
          || printf 'forge-nix-drift: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
        printf 'forge-nix-drift: receipt\t%s\n' "$line"
      }
      trap emit_receipt EXIT

      notify() {
        /usr/bin/osascript -e "display notification \"$1\" with title \"Forge Nix drift\"" >/dev/null 2>&1 || true
      }

      # Scheduled runs stay AC-gated: a moved input triggers a full host build.
      if [ "$mode" = "scheduled" ]; then
        /usr/bin/pmset -g batt | grep "AC Power" >/dev/null || {
          power="battery" result="skipped"
          exit 0
        }
        power="ac"
        flock_args=(-n)
      else
        flock_args=(-w 600)
      fi
      # Own lock serializes drift runs; the deploy flock stays redeploy-owned,
      # so an in-flight deploy surfaces as build=deploy-in-flight, not deadlock.
      mkdir -p "$(dirname "$lock_file")"
      exec 8>"$lock_file"
      flock "''${flock_args[@]}" 8 || {
        lock="held" result="skipped"
        printf 'forge-nix-drift: another drift run holds %s; skipped\n' "$lock_file" >&2
        exit 75
      }
      lock="ok"

      [ -f "$forge_root/flake.nix" ] || {
        printf 'forge-nix-drift: missing flake root: %s\n' "$forge_root" >&2
        exit 1
      }
      cd "$forge_root"

      tmpdir="$(mktemp -d "''${TMPDIR:-/tmp}/forge-nix-drift.XXXXXX")"
      trap 'emit_receipt; rm -rf "$tmpdir"' EXIT

      # Installed daemon vs pinned artifact: Determinate version drift is a
      # separate object from flake-input drift and only ever notifies.
      pinned="$(jq -r '.nodes."determinate-nixd-aarch64-darwin".locked.url // ""' flake.lock | grep -o 'v[0-9.]*' || true)"
      installed="$(/usr/local/bin/determinate-nixd version 2>/dev/null | awk '/daemon version:/ {print "v" $NF; exit}' || true)"
      nixd="''${installed:--}:''${pinned:--}"

      # Root-input identity snapshot; the pre/post join names moved inputs.
      snap() {
        jq -r '. as $l | $l.nodes.root.inputs | to_entries[]
          | .key + "\t" + ($l.nodes[.value].locked.rev // $l.nodes[.value].locked.url // "-")' flake.lock | sort
      }

      dirty_total="$(git status --porcelain | wc -l | tr -d ' ')"
      if [ "$dirty_total" = 0 ]; then worktree="clean"; else worktree="dirty-$dirty_total"; fi

      # Bump only when the flake pair is untouched: uncommitted operator or
      # thread edits to flake.nix/flake.lock must never be entangled.
      if [ -n "$(git status --porcelain -- flake.nix flake.lock)" ]; then
        bump="skipped-dirty"
      else
        snap >"$tmpdir/pre"
        # A failed update (network/registry) is withdrawn and notified; a
        # partially written lock must never wedge later runs into skipped-dirty.
        if ! nix flake update; then
          git checkout -- flake.lock
          bump="fail"
          notify "Flake update failed; lock kept at HEAD."
          exit 1
        fi
        if [ -z "$(git status --porcelain -- flake.lock)" ]; then
          bump="current"
        else
          bump="moved"
          snap >"$tmpdir/post"
          inputs="$(join -t "$(printf '\t')" "$tmpdir/pre" "$tmpdir/post" \
            | awk -F '\t' '$2 != $3 {print $1}' | paste -sd, -)"
          [ -n "$inputs" ] || inputs="transitive"
        fi
      fi

      # Receipt-proved build through the deploy owner; --build also owns the
      # cache push, so drift keeps one cache-publication rail (no dual paths).
      if forge-redeploy --build >"$tmpdir/redeploy" 2>&1; then
        build="ok"
      else
        rc=$?
        if [ "$rc" = 75 ]; then build="deploy-in-flight"; else build="fail"; fi
      fi
      cat "$tmpdir/redeploy"

      # A bump that did not prove buildable is withdrawn, keeping HEAD's lock
      # the last known-good; the failure receipt carries the moved-input list.
      if [ "$bump" = "moved" ] && [ "$build" != "ok" ]; then
        git checkout -- flake.lock
        bump="reverted"
      fi

      if [ "$bump" = "moved" ]; then
        if git -c commit.gpgsign=false commit -m "nix: bump flake inputs ($inputs)" -- flake.lock >/dev/null; then
          commit="ok"
        else
          commit="failed"
          # An uncommitted bump gates every later run into skipped-dirty;
          # notify once here so the wedge never accrues silently.
          notify "Lock bump built but commit failed; flake.lock left uncommitted."
          printf 'forge-nix-drift: WARNING lock bump built but commit failed; flake.lock left uncommitted\n' >&2
        fi
      fi

      if [ "$build" = "ok" ]; then
        system_path="$(awk -F 'system=' '/forge-redeploy: build ok system=/ {print $2; exit}' "$tmpdir/redeploy")"
        if [ -n "$system_path" ] && [ -e /run/current-system ]; then
          if [ "$(readlink /run/current-system)" = "$system_path" ]; then deployed="match"; else deployed="drift"; fi
        fi
      fi

      case "$build" in
        ok)
          result="ok"
          if [ "$commit" = "failed" ]; then result="partial"; fi
          if [ "$bump" = "moved" ]; then
            notify "Inputs bumped ($inputs); build proved. Switch when ready."
          elif [ "$deployed" = "drift" ]; then
            notify "Declared system differs from deployed; forge-redeploy --switch converges."
          fi
          if [ -n "$installed" ] && [ -n "$pinned" ] && [ "$installed" != "$pinned" ]; then
            notify "determinate-nixd $installed installed, $pinned pinned; switch or upgrade."
          fi
          ;;
        deploy-in-flight)
          result="skipped"
          ;;
        *)
          notify "Drift build failed; inspect ~/Library/Logs/forge-nix-drift.log"
          exit 1
          ;;
      esac
    '';
  };

  # Sweep rows: HM-managed roots where a stale root-owned store hardlink from
  # a prior generation blocks the user-mode backup/relink during activation.
  # exempt names are root-owned by design (daemon state), never in-the-way.
  sweepRows = pkgs.writeText "forge-activation-sweep-rows.json" (builtins.toJSON [
    {
      root = ".config";
      exempt = [];
    }
    {
      root = ".local/share";
      exempt = [];
    }
    {
      root = ".local/state";
      exempt = ["systems.determinate.detsys-ids-client"];
    }
    {
      root = ".hammerspoon";
      exempt = [];
    }
    {
      root = "Library/LaunchAgents";
      exempt = [];
    }
  ]);

  # Pre-activation guard for the gen-810 class: detect root-owned in-the-way
  # HM targets, clear them in one sudo batch, prove the clear with a receipt.
  forgeActivationSweep = pkgs.writeShellApplication {
    name = "forge-activation-sweep";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.jq];
    text = ''
      case "''${1:-}" in
        "") mode="detect" ;;
        --clear) mode="clear" ;;
        *)
          printf 'Usage: forge-activation-sweep [--clear]\n' >&2
          exit 2
          ;;
      esac
      receipt_log="''${FORGE_SWEEP_RECEIPT_LOG:-$HOME/Library/Logs/forge-activation-sweep.receipts.log}"
      ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      findings=0 cleared="-" result="fail"
      emit_receipt() {
        line="$(printf 'ts=%s\tmode=%s\tfindings=%s\tcleared=%s\tresult=%s' \
          "$ts" "$mode" "$findings" "$cleared" "$result")"
        { mkdir -p "$(dirname "$receipt_log")" && printf '%s\n' "$line" >>"$receipt_log"; } \
          || printf 'forge-activation-sweep: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
        printf 'forge-activation-sweep: receipt\t%s\n' "$line"
      }
      tmpdir="$(mktemp -d "''${TMPDIR:-/tmp}/forge-activation-sweep.XXXXXX")"
      trap 'emit_receipt; rm -rf "$tmpdir"' EXIT

      # Topmost root-owned entries only: -prune stops descent so one finding
      # covers a whole in-the-way tree; rm -rf clears its children with it.
      scan() {
        while IFS= read -r row; do
          root="$(jq -r '.root' <<<"$row")"
          [ -d "$HOME/$root" ] || continue
          while IFS= read -r -d "" p; do
            if jq -e --arg b "''${p##*/}" '.exempt | index($b)' <<<"$row" >/dev/null; then continue; fi
            printf '%s\0' "$p"
          done < <(find "$HOME/$root" -uid 0 -prune -print0 2>/dev/null)
        done < <(jq -c '.[]' '${sweepRows}')
      }

      scan >"$tmpdir/findings"
      findings="$(tr -cd '\0' <"$tmpdir/findings" | wc -c | tr -d ' ')"

      if [ "$findings" = 0 ]; then
        result="ok"
        printf 'forge-activation-sweep: clean\n'
        exit 0
      fi
      xargs -0 -n 1 printf 'forge-activation-sweep: in-the-way\t%s\n' <"$tmpdir/findings"

      if [ "$mode" = "detect" ]; then
        result="found"
        printf 'forge-activation-sweep: %s root-owned target(s); rerun with --clear before switching\n' "$findings"
        exit 4
      fi

      # One sudo batch per approval (Touch ID); cleared trees are store
      # hardlinks, so the next switch regenerates them user-owned. A scan
      # root itself is never bulk-deleted: it stays a reported finding for
      # manual repair, so --clear cannot become rm -rf of a whole home root.
      paths=()
      while IFS= read -r -d "" p; do
        if jq -e --arg h "$HOME" --arg p "$p" 'map($h + "/" + .root) | index($p)' '${sweepRows}' >/dev/null; then
          printf 'forge-activation-sweep: refusing to clear scan root\t%s\n' "$p" >&2
        else
          paths+=("$p")
        fi
      done <"$tmpdir/findings"
      if [ "''${#paths[@]}" -gt 0 ]; then
        sudo /bin/rm -rf -- "''${paths[@]}"
      fi
      scan >"$tmpdir/residual"
      remaining="$(tr -cd '\0' <"$tmpdir/residual" | wc -c | tr -d ' ')"
      cleared=$((findings - remaining))
      if [ "$remaining" = 0 ]; then result="ok"; else result="partial"; fi
      printf 'forge-activation-sweep: cleared %s of %s\n' "$cleared" "$findings"
      # A partial clear must fail loudly: a chained switch would still hit
      # the remaining in-the-way targets.
      [ "$remaining" = 0 ] || exit 4
    '';
  };
in {
  home.packages = [
    forgeRedeploy
    forgeNixMaintenance
    forgeCleanup
    forgeNixDrift
    forgeActivationSweep
  ];

  # Weekly off-peak cadence; the shared flock serializes against deploys.
  launchd.agents.forge-nix-maintenance = {
    enable = true;
    config = {
      ProgramArguments = ["${forgeNixMaintenance}/bin/forge-nix-maintenance" "--scheduled"];
      StartCalendarInterval = [
        {
          Weekday = 6;
          Hour = 12;
          Minute = 0;
        }
      ];
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-nix-maintenance.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-nix-maintenance.log";
    };
  };

  # Daily 10:00 currency cadence (operator ruling); calendar-only, no
  # RunAtLoad: login must never race a live campaign with a lock bump.
  launchd.agents.forge-nix-drift = {
    enable = true;
    config = {
      ProgramArguments = ["${forgeNixDrift}/bin/forge-nix-drift" "--scheduled"];
      StartCalendarInterval = [
        {
          Hour = 10;
          Minute = 0;
        }
      ];
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-nix-drift.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-nix-drift.log";
    };
  };
}
