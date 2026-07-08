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

      lock_file="''${FORGE_REDEPLOY_LOCK:-$HOME/.cache/forge-redeploy.lock}"
      nix_env="/nix/var/nix/profiles/default/bin/nix-env"

      # Scheduled runs stay AC-gated and yield to a live deploy; manual runs wait.
      # No grep -q: consuming all input avoids the pipefail/SIGPIPE false skip.
      if [ "''${1:-}" = "--scheduled" ]; then
        /usr/bin/pmset -g batt | grep "AC Power" >/dev/null || {
          printf 'forge-nix-maintenance: on battery; skipped\n'
          exit 0
        }
        flock_args=(-n)
      else
        flock_args=(-w 600)
      fi
      mkdir -p "$(dirname "$lock_file")"
      exec 9>"$lock_file"
      flock "''${flock_args[@]}" 9 || {
        printf 'forge-nix-maintenance: deploy in flight holds %s; skipped\n' "$lock_file" >&2
        exit 75
      }

      # System generations: keep the newest five for the rollback window.
      status="ok"
      sudo -n "$nix_env" -p /nix/var/nix/profiles/system --delete-generations +5 || {
        status="partial"
        printf 'forge-nix-maintenance: WARNING system generation trim denied; rerun after a switch lands the sudoers row\n' >&2
      }
      # User profiles: drop stale generations and collect what they unpinned;
      # continuous free-space GC stays determinate-nixd-owned.
      nix-collect-garbage --delete-older-than 14d
      nix store optimise
      printf 'forge-nix-maintenance: %s ts=%s\n' "$status" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    '';
  };

  forgeContainerDoctor = pkgs.writeShellApplication {
    name = "forge-container-doctor";
    runtimeInputs = [pkgs.coreutils pkgs.docker-client pkgs.docker-compose pkgs.jq];
    text = ''
      socket="''${DOCKER_HOST:-unix://$HOME/.local/share/colima/default/docker.sock}"
      config="''${DOCKER_CONFIG:-$HOME/.config/docker}"
      printf 'container-doctor\tendpoint_kind=%s\n' "''${socket%%://*}"
      if [[ "$socket" == unix://* ]]; then
        socket_path="''${socket#unix://}"
        [ -S "$socket_path" ] || {
          printf 'container-doctor\tok=false\treason=missing-socket\n'
          exit 1
        }
      fi
      if [ -f "$config/config.json" ]; then
        helper_count="$(jq -r '((.credsStore // .credStore // "") != "") as $store | (($store | if . then 1 else 0 end) + ((.credHelpers // {}) | length))' "$config/config.json")"
      else
        helper_count=0
      fi
      DOCKER_HOST="$socket" DOCKER_CONFIG="$config" docker version >/dev/null
      DOCKER_HOST="$socket" DOCKER_CONFIG="$config" docker compose version >/dev/null
      printf 'container-doctor\tok=true\tcredential_helpers=%s\n' "$helper_count"
    '';
  };
in {
  home.packages = [
    forgeRedeploy
    forgeNixMaintenance
    forgeContainerDoctor
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
}
