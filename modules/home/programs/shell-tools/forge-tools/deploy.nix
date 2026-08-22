# Title         : deploy.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools/deploy.nix
# ----------------------------------------------------------------------------
# Deploy rail: forge-redeploy (the only activation path), forge-nix-maintenance (scheduled lifecycle), and forge-activation-sweep (pre-activation
# guard) — all sharing the redeploy lock; the maintenance agent adds the AC gate.
{
  lib,
  pkgs,
  tl,
}: rec {
  forgeRedeploy = tl.mkTool {
    name = "forge-redeploy";
    storePath = true;
    inputs = [pkgs.coreutils pkgs.gawk pkgs.git pkgs.nh pkgs.nix-output-monitor pkgs.dix pkgs.nvd pkgs.cachix pkgs.flock pkgs.nixos-rebuild-ng];
    text = ''
      # Polymorphic OS dispatch: one deploy rail, per-OS execution. Darwin builds/switches locally; NixOS check is eval-only (no Linux builder
      # assumed), build proves a closure, switch activates locally on a NixOS host or remotely through nixos-rebuild-ng --target-host.
      mode="check"
      # Default --os keys on the running kernel: a NixOS host must never ride the darwin rail by default; FORGE_OS and --os stay explicit overrides.
      os="''${FORGE_OS:-$(case "$(uname -s)" in Linux) echo nixos ;; *) echo darwin ;; esac)}"
      host="''${FORGE_HOST:-}"
      target_host="''${FORGE_TARGET_HOST:-}"
      usage() {
        printf 'Usage: forge-redeploy [--os darwin|nixos] [--host NAME] [--target-host SSH]\n'
        printf '                      [--check-only|--build|--switch]\n'
      }
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --check-only) mode="check" ;;
          --build) mode="build" ;;
          --switch) mode="switch" ;;
          --os)
            os="''${2:?forge-redeploy: --os requires darwin|nixos}"
            shift
            ;;
          --host)
            host="''${2:?forge-redeploy: --host requires a flake host name}"
            shift
            ;;
          --target-host)
            target_host="''${2:?forge-redeploy: --target-host requires an ssh destination}"
            shift
            ;;
          --help | -h)
            usage
            exit 0
            ;;
          *)
            printf 'forge-redeploy: unknown argument: %s\n' "$1" >&2
            exit 2
            ;;
        esac
        shift
      done
      case "$os" in
        darwin | nixos) ;;
        *)
          printf 'forge-redeploy: --os must be darwin or nixos, got: %s\n' "$os" >&2
          exit 2
          ;;
      esac
      if [ -z "$host" ]; then
        if [ "$os" = "darwin" ]; then host="macbook"; else host="vps"; fi
      fi

      forge_root="${tl.forgeRootExpr}"
      cache="''${CACHIX_CACHE:-bsamiee}"
      secrets_file="''${FORGE_SECRETS_FILE:-''${XDG_CONFIG_HOME:-$HOME/.config}/forge-session-secrets.sh}"
      lock_file="${tl.redeployLockExpr}"
      custom_conf="/etc/nix/nix.custom.conf"
      profile="/nix/var/nix/profiles/system"
      nix_env="/nix/var/nix/profiles/default/bin/nix-env"

      # One flock serializes deploys and the maintenance agent.
      mkdir -p "$(dirname "$lock_file")"
      exec {lock_fd}>"$lock_file"
      flock -n "$lock_fd" || {
        printf 'forge-redeploy: another deploy/maintenance run holds %s\n' "$lock_file" >&2
        exit 75
      }

      # One typed receipt per state-touching run; the EXIT trap emits it even when a phase aborts, so failed activations stay visible (result=fail).
      system_path="-" gen_live="-"
      eval_s="-" build_s="-" activate_s="-"
      diff_lines="-"
      push="-" verify="-" kickstart="-" current="-"
      mux="''${ZELLIJ_SESSION_NAME:+zellij}"
      result="fail"
      emit_receipt() {
        persist_receipt "$(printf 'ts=%s\tmode=%s\tos=%s\thost=%s\ttarget=%s\tsystem=%s\tgen=%s\teval_s=%s\tbuild_s=%s\tactivate_s=%s\tdiff_lines=%s\tpush=%s\tverify=%s\tkickstart=%s\tcurrent=%s\tmux=%s\tresult=%s' \
          "$ts" "$mode" "$os" "$host" "''${target_host:--}" "$system_path" "$gen_live" "$eval_s" "$build_s" "$activate_s" \
          "$diff_lines" "$push" "$verify" "$kickstart" \
          "$current" "''${mux:-none}" "$result")"
      }

      tmpdir="$(mktemp -d "''${TMPDIR:-/tmp}/forge-redeploy.XXXXXX")"
      trap 'emit_receipt; rm -rf "$tmpdir"' EXIT
      trap 'exit 143' TERM
      trap 'exit 130' INT
      out_link="$tmpdir/system"

      # Backend-dispatched token resolution: ambient CACHIX_AUTH_TOKEN wins, the session-secrets dispatcher (FORGE_SECRETS_FILE) resolves the machine
      # rail, absence degrades to a skipped push. A present-but-bad token never fails an already-built/switched deploy.
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
          # Narinfo round-trip proves the closure is servable, not just sent. negative-ttl 0: the dry-run proof caches a pre-push miss for this exact
          # path; an unexpired entry would fake verify=missing.
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

      # Single owner of the post-activation contract: generation capture, live-system equality, then the daemon
      # kickstart. $1 = expected store path, $2 = its label.
      assert_live() {
        gen_live="$(readlink "$profile" 2>/dev/null)" || gen_live="-"
        gen_live="''${gen_live##*system-}"
        gen_live="''${gen_live%-link}"
        live_system="$(readlink /run/current-system)"
        if [ "$live_system" != "$1" ]; then
          current="mismatch"
          printf 'forge-redeploy: FATAL live system %s != %s %s\n' "$live_system" "$2" "$1" >&2
          exit 1
        fi
        current="match"
        run_kickstart
      }

      # Activation's /etc collision guard exits 2 on an installer-written real file; one adoption owner serves the switch activation.
      adopt_custom_conf() {
        { [ -f "$custom_conf" ] && [ ! -L "$custom_conf" ]; } || return 0
        sudo -n /bin/mv "$custom_conf" "$custom_conf.before-determinate-module" || {
          printf 'forge-redeploy: %s is a real file and blocks activation.\n' "$custom_conf" >&2
          printf 'forge-redeploy: run once: sudo mv %s %s.before-determinate-module\n' "$custom_conf" "$custom_conf" >&2
          exit 1
        }
      }

      [ -f "$forge_root/flake.nix" ] || {
        printf 'forge-redeploy: missing flake root: %s\n' "$forge_root" >&2
        exit 1
      }
      cd "$forge_root"

      printf 'forge-redeploy: nix=%s\n' "$(command -v nix)"
      t0=$EPOCHSECONDS
      nix flake check --print-build-logs

      if [ "$os" = "darwin" ]; then
        attr="darwinConfigurations.$host.system"
      else
        attr="nixosConfigurations.$host.config.system.build.toplevel"
      fi
      eval_s=$((EPOCHSECONDS - t0))

      # NixOS dispatch: eval-only check (drv identity), real-closure build, local nh switch on a NixOS host, remote target-built switch otherwise.
      if [ "$os" = "nixos" ]; then
        t0=$EPOCHSECONDS
        case "$mode" in
          check)
            system_path="$(nix eval --raw "$forge_root#$attr.drvPath")"
            build_s=$((EPOCHSECONDS - t0))
            result="ok"
            printf 'forge-redeploy: check-only ok (eval) drv=%s\n' "$system_path"
            ;;
          build)
            system_path="$(nix build --no-link --print-out-paths "$forge_root#$attr")"
            build_s=$((EPOCHSECONDS - t0))
            push_cache "$system_path"
            result="ok"
            printf 'forge-redeploy: build ok system=%s\n' "$system_path"
            ;;
          switch)
            if [ "$(uname -s)" = "Linux" ] && [ -z "$target_host" ]; then
              nh os switch --hostname "$host" "$forge_root"
              build_s=$((EPOCHSECONDS - t0))
              system_path="$(readlink -f /run/current-system)"
            else
              [ -n "$target_host" ] || {
                printf 'forge-redeploy: --switch --os nixos from Darwin needs --target-host\n' >&2
                exit 2
              }
              system_path="$(nix eval --raw "$forge_root#$attr.drvPath")"
              # Target-built activation: no local Linux builder is assumed; nixos-rebuild-ng evaluates locally and builds on the target. The -ng
              # package ships its binary as plain nixos-rebuild; --no-reexec stops the cross-platform local self-rebuild.
              sudo_flag=(--sudo)
              case "$target_host" in root@*) sudo_flag=() ;; esac
              t1=$EPOCHSECONDS
              nixos-rebuild switch --flake "$forge_root#$host" --no-reexec \
                --target-host "$target_host" --build-host "$target_host" \
                "''${sudo_flag[@]}"
              activate_s=$((EPOCHSECONDS - t1))
              build_s=$((EPOCHSECONDS - t0))
            fi
            result="ok"
            printf 'forge-redeploy: switch ok os=nixos host=%s target=%s system=%s\n' \
              "$host" "''${target_host:-local}" "$system_path"
            ;;
        esac
        exit 0
      fi

      # Every Darwin mode builds the toplevel through nh and reviews the diff.
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
          # Exact-closure activation: the reviewed store path is registered and activated directly, never re-evaluated.
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
          # Post-activation steps degrade to warnings: the deploy already landed. Push precedes the kickstart so it never races the daemon restart.
          push_cache "$system_path"
          assert_live "$system_path" "built"
          result="ok"
          printf 'forge-redeploy: switch ok system=%s\n' "$system_path"
          ;;
      esac
    '';
  };

  # Scheduled lifecycle owner for what determinate-nixd does not schedule: generation retention and store optimise; background GC stays daemon-owned.
  forgeNixMaintenance = tl.mkTool {
    name = "forge-nix-maintenance";
    storePath = true;
    inputs = [pkgs.coreutils pkgs.gnugrep pkgs.flock];
    text = ''
      # Reject unknown argv up front: a typo must never silently run as a manual pass (600s lock wait, no AC gate).
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
      lock_file="${tl.redeployLockExpr}"
      nix_env="/nix/var/nix/profiles/default/bin/nix-env"

      # One typed receipt per run; the EXIT trap emits it even when a phase aborts, so denied trims and failed GC stay visible (result=fail).
      power="-" lock="-" trim="-" gc="-" optimise="-"
      gc_s="-" optimise_s="-"
      result="fail"
      emit_receipt() {
        persist_receipt "$(printf 'ts=%s\tmode=%s\tpower=%s\tlock=%s\ttrim=%s\tgc=%s\tgc_s=%s\toptimise=%s\toptimise_s=%s\tresult=%s' \
          "$ts" "$mode" "$power" "$lock" "$trim" "$gc" "$gc_s" "$optimise" "$optimise_s" "$result")"
      }
      trap emit_receipt EXIT

      ${tl.acGateFold}
      mkdir -p "$(dirname "$lock_file")"
      exec {lock_fd}>"$lock_file"
      flock "''${flock_args[@]}" "$lock_fd" || {
        lock="held" result="skipped"
        printf 'forge-nix-maintenance: deploy in flight holds %s; skipped\n' "$lock_file" >&2
        exit 75
      }
      lock="ok"

      # System generations: current-only policy; the NOPASSWD row pins these exact args, so a denial signals policy drift.
      trim="ok"
      sudo -n "$nix_env" -p /nix/var/nix/profiles/system --delete-generations old || {
        trim="denied"
        printf 'forge-nix-maintenance: WARNING system generation trim denied; rerun after a switch lands the sudoers row\n' >&2
      }
      # User profiles: drop every non-current generation and collect; continuous free-space GC stays determinate-nixd-owned.
      t0=$EPOCHSECONDS
      nix-collect-garbage -d
      gc="ok" gc_s=$((EPOCHSECONDS - t0))
      t0=$EPOCHSECONDS
      nix store optimise
      optimise="ok" optimise_s=$((EPOCHSECONDS - t0))
      result="ok"
      [ "$trim" = "ok" ] || result="partial"
    '';
  };

  # Sweep rows: HM-managed roots where a stale root-owned store hardlink from a prior generation blocks the user-mode backup/relink during activation;
  # exempt basenames are root-owned by design (daemon state), never in-the-way.
  sweepRows = pkgs.writeText "forge-activation-sweep-rows.json" (builtins.toJSON (lib.mapAttrsToList
    (root: exempt: {inherit root exempt;})
    {
      ".config" = [];
      ".local/share" = [];
      ".local/state" = ["systems.determinate.detsys-ids-client"];
      ".hammerspoon" = [];
      "Library/LaunchAgents" = [];
    }));

  # Pre-activation guard: detect root-owned in-the-way HM targets, clear them in one sudo batch, prove the clear with a receipt.
  forgeActivationSweep = tl.mkTool {
    name = "forge-activation-sweep";
    inputs = [pkgs.coreutils pkgs.findutils pkgs.jq];
    text = ''
      case "''${1:-}" in
        "") mode="detect" ;;
        --clear) mode="clear" ;;
        *)
          printf 'Usage: forge-activation-sweep [--clear]\n' >&2
          exit 2
          ;;
      esac
      findings=0 cleared="-" result="fail"
      emit_receipt() {
        persist_receipt "$(printf 'ts=%s\tmode=%s\tfindings=%s\tcleared=%s\tresult=%s' \
          "$ts" "$mode" "$findings" "$cleared" "$result")"
      }
      tmpdir="$(mktemp -d "''${TMPDIR:-/tmp}/forge-activation-sweep.XXXXXX")"
      trap 'emit_receipt; rm -rf "$tmpdir"' EXIT
      trap 'exit 143' TERM
      trap 'exit 130' INT

      # Topmost root-owned entries only: -prune stops descent so one finding covers a whole in-the-way tree; rm -rf clears its children with it.
      scan() {
        while IFS= read -r row; do
          root="$(printf '%s\n' "$row" | jq -r '.root')"
          [ -d "$HOME/$root" ] || continue
          while IFS= read -r -d "" p; do
            if printf '%s\n' "$row" | jq -e --arg b "''${p##*/}" '.exempt | index($b)' >/dev/null; then continue; fi
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

      # One sudo batch per approval (Touch ID); cleared trees are store hardlinks, so the next switch regenerates them user-owned. A scan root itself
      # is never bulk-deleted: it stays a reported finding for manual repair, so --clear cannot become rm -rf of a whole home root.
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
      # A partial clear must fail loudly: a chained switch would still hit the remaining in-the-way targets.
      [ "$remaining" = 0 ] || exit 4
    '';
  };
}
