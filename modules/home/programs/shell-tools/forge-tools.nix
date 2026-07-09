# Title         : forge-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-tools.nix
# ----------------------------------------------------------------------------
# Agent-safe Forge maintenance entrypoints: deploy rail, hygiene board,
# doctors, parity, acceptance choreography.
{
  config,
  lib,
  pkgs,
  ...
}: let
  logs = "${config.home.homeDirectory}/Library/Logs";
  bundleId = "com.parametric-forge.forge-nix-automation";

  # One builder owns the shared tool rail: UTC stamp, per-tool receipt-log
  # override (FORGE_<NAME>_RECEIPT_LOG), one persist function every receipt
  # emitter calls. storePath prepends the Determinate profile so every
  # nix/nix-env call (incl. nh's) resolves the daemon-matched client.
  mkTool = {
    name,
    inputs ? [],
    receiptName ? name,
    storePath ? false,
    text,
  }: let
    envKey = "FORGE_${lib.toUpper (lib.replaceStrings ["-"] ["_"] (lib.removePrefix "forge-" receiptName))}_RECEIPT_LOG";
  in
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = inputs;
      text =
        lib.optionalString storePath ''
          export PATH="/nix/var/nix/profiles/default/bin:$PATH"
        ''
        + ''
          TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
          receipt_log="''${${envKey}:-$HOME/Library/Logs/${receiptName}.receipts.log}"
          # An unwritable log must never fail a trap or mask a landed run.
          persist_receipt() {
            { mkdir -p "''${receipt_log%/*}" && printf '%s\n' "$1" >>"$receipt_log"; } \
              || printf '${name}: WARNING receipt not persisted to %s\n' "$receipt_log" >&2
            printf '${name}: receipt\t%s\n' "$1"
          }
        ''
        + text;
    };

  forgeRedeploy = mkTool {
    name = "forge-redeploy";
    storePath = true;
    inputs = [pkgs.coreutils pkgs.gawk pkgs.git pkgs.nh pkgs.nix-output-monitor pkgs.dix pkgs.nvd pkgs.cachix pkgs.flock pkgs.nixos-rebuild-ng];
    text = ''
      # Polymorphic OS dispatch: one deploy rail, per-OS execution. Darwin
      # builds/switches locally; NixOS check is eval-only (no Linux builder
      # assumed), build proves a closure, switch activates locally on a NixOS
      # host or remotely through nixos-rebuild-ng --target-host.
      mode="check"
      gen=""
      os="''${FORGE_OS:-darwin}"
      host="''${FORGE_HOST:-}"
      target_host="''${FORGE_TARGET_HOST:-}"
      usage() {
        printf 'Usage: forge-redeploy [--os darwin|nixos] [--host NAME] [--target-host SSH]\n'
        printf '                      [--check-only|--build|--switch|--rollback [gen]|--generations]\n'
      }
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --check-only) mode="check" ;;
          --build) mode="build" ;;
          --switch) mode="switch" ;;
          --rollback)
            mode="rollback"
            if [[ "''${2:-}" =~ ^[0-9]+$ ]]; then
              gen="$2"
              shift
            fi
            ;;
          --generations) mode="generations" ;;
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
        if [ "$os" = "darwin" ]; then host="macbook"; else host="maghz"; fi
      fi
      if [ "$os" = "nixos" ] && { [ "$mode" = "generations" ] || [ "$mode" = "rollback" ]; }; then
        printf 'forge-redeploy: %s is Darwin-local; NixOS generations live on the target (nixos-rebuild-ng list-generations / --rollback over ssh)\n' "$mode" >&2
        exit 2
      fi

      forge_root="''${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}"
      cache="''${CACHIX_CACHE:-bsamiee}"
      secrets_file="''${FORGE_SECRETS_FILE:-''${XDG_CONFIG_HOME:-$HOME/.config}/forge-session-secrets.sh}"
      lock_file="''${FORGE_REDEPLOY_LOCK:-$HOME/.cache/forge-redeploy.lock}"
      custom_conf="/etc/nix/nix.custom.conf"
      profile="/nix/var/nix/profiles/system"
      nix_env="/nix/var/nix/profiles/default/bin/nix-env"
      rebuild="/run/current-system/sw/bin/darwin-rebuild"

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
      exec {lock_fd}>"$lock_file"
      flock -n "$lock_fd" || {
        printf 'forge-redeploy: another deploy/maintenance run holds %s\n' "$lock_file" >&2
        exit 75
      }

      # One typed receipt per state-touching run; the EXIT trap emits it even
      # when a phase aborts, so failed activations stay visible (result=fail).
      system_path="-" gen_live="-"
      eval_s="-" build_s="-" activate_s="-"
      to_build="-" to_fetch="-" diff_lines="-"
      push="-" verify="-" kickstart="-" current="-"
      mux="''${ZELLIJ_SESSION_NAME:+zellij}"
      result="fail"
      emit_receipt() {
        persist_receipt "$(printf 'ts=%s\tmode=%s\tos=%s\thost=%s\ttarget=%s\tsystem=%s\tgen=%s\teval_s=%s\tbuild_s=%s\tactivate_s=%s\tto_build=%s\tto_fetch=%s\tdiff_lines=%s\tpush=%s\tverify=%s\tkickstart=%s\tcurrent=%s\tmux=%s\tresult=%s' \
          "$ts" "$mode" "$os" "$host" "''${target_host:--}" "$system_path" "$gen_live" "$eval_s" "$build_s" "$activate_s" \
          "$to_build" "$to_fetch" "$diff_lines" "$push" "$verify" "$kickstart" \
          "$current" "''${mux:-none}" "$result")"
      }

      tmpdir="$(mktemp -d "''${TMPDIR:-/tmp}/forge-redeploy.XXXXXX")"
      trap 'emit_receipt; rm -rf "$tmpdir"' EXIT
      out_link="$tmpdir/system"

      # Backend-dispatched token resolution: ambient CACHIX_AUTH_TOKEN wins, the
      # session-secrets dispatcher (FORGE_SECRETS_FILE) resolves the machine
      # rail, absence degrades to a skipped push. A present-but-bad token never
      # fails an already-built/switched deploy.
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
        live_system="$(readlink /run/current-system)"
        if [ "$live_system" != "$1" ]; then
          current="mismatch"
          printf 'forge-redeploy: FATAL live system %s != %s %s\n' "$live_system" "$2" "$1" >&2
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
        assert_live "$(<"$profile/systemConfig")" "rolled-back profile"
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

      if [ "$os" = "darwin" ]; then
        attr="darwinConfigurations.$host.system"
      else
        attr="nixosConfigurations.$host.config.system.build.toplevel"
      fi

      # Pre-build proof: to-build/to-fetch counts expose derivation-identity
      # drift (the 1h local-rebuild class) the day it appears. Parsing is
      # version-sensitive and degrades to unknown, never fails the deploy.
      if nix build --dry-run --no-link "$forge_root#$attr" 2>"$tmpdir/dryrun"; then
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

      # NixOS dispatch: eval-only check (drv identity), real-closure build,
      # local nh switch on a NixOS host, remote target-built switch otherwise.
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
              # Target-built activation: no local Linux builder is assumed;
              # nixos-rebuild-ng evaluates locally and builds on the target.
              # The -ng package ships its binary as plain nixos-rebuild;
              # --no-reexec stops the cross-platform local self-rebuild.
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
  forgeNixMaintenance = mkTool {
    name = "forge-nix-maintenance";
    storePath = true;
    inputs = [pkgs.coreutils pkgs.gnugrep pkgs.flock];
    text = ''
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
      nix_env="/nix/var/nix/profiles/default/bin/nix-env"

      # One typed receipt per run; the EXIT trap emits it even when a phase
      # aborts, so denied trims and failed GC stay visible (result=fail).
      power="-" lock="-" trim="-" gc="-" optimise="-"
      gc_s="-" optimise_s="-"
      result="fail"
      emit_receipt() {
        persist_receipt "$(printf 'ts=%s\tmode=%s\tpower=%s\tlock=%s\ttrim=%s\tgc=%s\tgc_s=%s\toptimise=%s\toptimise_s=%s\tresult=%s' \
          "$ts" "$mode" "$power" "$lock" "$trim" "$gc" "$gc_s" "$optimise" "$optimise_s" "$result")"
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
      exec {lock_fd}>"$lock_file"
      flock "''${flock_args[@]}" "$lock_fd" || {
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

  # Cleanup registry as a tuple grammar: one row per line, projected to typed
  # JSON through rowGrammar. Kinds — mode: converge a directory mode; path:
  # trash a residue tree; glob: trash matches under a root; age: retention
  # window (the age gate IS the live-session guard); deadlink: trash broken
  # links only; ledger: report-only storage budget; adjudicate: named
  # decision, receipt-only; codex-trust: prune stale trusted-project rows;
  # orphan: ppid-1 agent-lane census — kill rows reap, report rows observe.
  rowGrammar = {
    mode = ["target" "expect"];
    path = ["target"];
    glob = ["root" "pattern" "depth"];
    age = ["root" "maxAgeDays" "pattern"];
    deadlink = ["root" "depth"];
    ledger = ["target" "budgetGb" "owner" "prune"];
    adjudicate = ["target" "decision" "note"];
    codex-trust = ["target"];
    orphan = ["match" "exclude" "minAgeSec" "action"];
  };
  projectRows = registry:
    lib.concatLists (lib.mapAttrsToList
      (kind: rows:
        lib.mapAttrsToList
        (name: v: {inherit name kind;} // lib.listToAttrs (lib.zipListsWith lib.nameValuePair rowGrammar.${kind} (lib.toList v)))
        rows)
      registry);

  cleanupRows = pkgs.writeText "forge-cleanup-rows.json" (builtins.toJSON (projectRows {
    mode.launchagents-mode = ["Library/LaunchAgents" "700"];
    # Map-proven residue candidates the detector re-proves live before any
    # action; every deletion is trash-first and restorable. cargo/rustup carry
    # the closed retirement decision: the toolchains are retired, regrowth is
    # litter. update-notifier configstore rows are unowned litter by CA-2
    # admission policy (self-mutating state disabled at admission).
    path = {
      pyenv-residue = ".pyenv";
      cargo-residue = ".cargo";
      rustup-residue = ".rustup";
      wez-sh-save = "bin/wez.sh.save";
      nix-defexpr-channels = ".nix-defexpr";
      csharp-history = ".config/csharp.history";
      homebrew-trust-lock = ".config/homebrew/trust.json.lock";
      crossnote-config = ".config/crossnote";
      opencode-config = ".config/opencode";
      update-notifier-configstore = ".config/configstore";
      carapace-empty-shell = ".config/carapace";
      colima-config-stub = ".config/colima";
      colima-root-dot = ".colima";
      xdg-ssh-residue = ".config/ssh";
      transmission-shell = ".config/transmission-daemon";
      sq-shell = ".config/sq";
      rest-client-shell = ".config/rest-client";
      rest-client-cache = ".cache/rest-client";
      ocrmypdf-cache-empty = ".cache/ocrmypdf";
      claude-cache-empty = ".cache/claude";
      antigravity-cache-empty = ".cache/antigravity";
      nx-shell = ".config/nx";
      nxcloud-shell = ".config/nxcloud";
      ruby-gem-residue = ".local/share/gem";
      shell-history-root-zsh = ".zsh_history";
      shell-dir-root-zsh = ".zsh";
      shell-history-root-bash = ".bash_history";
      bash-sessions-root = ".bash_sessions";
      browserlock-residue = ".BrowserLock";
      pdf-filler-profiles = ".pdf-filler-profiles";
      pdf-toolkit-files = ".pdf-toolkit-files";
      playwright-daemon-root = ".playwright-daemon";
      playwright-skill-root = ".playwright-skill";
      library-application-singleton = "Library/Application";
      photoshop-crashes = "Library/PhotoshopCrashes";
      library-staging = "Library/Staging";
      documents-codex-bucket = "Documents/Codex";
      documents-adobe-bucket = "Documents/Adobe";
      yazi-ds-store = ".config/yazi/.DS_Store";
      karabiner-auto-backups = ".config/karabiner/automatic_backups";
      vscode-insiders-state = "Library/Application Support/Code - Insiders";
      ipython-root-dot = ".ipython";
      matplotlib-root-dot = ".matplotlib";
      maven-m2-root-dot = ".m2";
      omnisharp-root-dot = ".omnisharp";
      templateengine-root-dot = ".templateengine";
      vscode-shared-root-dot = ".vscode-shared";
      servicehub-root-dot = ".ServiceHub";
      puccinialin-ownerless-cache = ".cache/puccinialin";
      cycles-ownerless-cache = ".cache/cycles";
      pause-note-tombstone = ".claude/dossiers/forge-rebuild/PAUSE-NOTE.md";
    };
    # wezterm-plugin-clone-cache enforces CA-4 provenance law: every runtime
    # plugin clone must resolve to a pinned store-path origin; the live cache
    # is empty — regrowth is litter.
    glob = {
      zdotdir-compdump = [".config/zsh" ".zcompdump*" 0];
      mcp-stage-litter = [".cache/forge-mcp" ".stage.*" 0];
      zshrc-backups = ["" ".zshrc.backup-*" 1];
      wezterm-plugin-clone-cache = ["Library/Application Support/wezterm/plugins" "*" 1];
      downloads-office-locks = ["Downloads" "~$*" 1];
      downloads-desktop-ini = ["Downloads" "desktop.ini" 1];
      documents-desktop-ini = ["Documents" "desktop.ini" 1];
      claude-stale-skills-review-project = [".claude/projects" "*claude-skills-review*" 1];
      agent-root-ds-store-claude = [".claude" ".DS_Store" 0];
      agent-root-ds-store-codex = [".codex" ".DS_Store" 0];
    };
    # Broken links trashed, live links untouched. docker-desktop rides the
    # endpoint-truth guard: HM-owned config.json and Colima socket facts stay
    # authoritative; only broken Docker Desktop links leave.
    deadlink = {
      wezterm-dead-listeners = [".local/share/wezterm" 1];
      docker-desktop-deadlinks = [".docker" 0];
      pnpm-project-store-danglers = [".local/share/pnpm/store/v11/projects" 0];
      mise-tracked-danglers = [".local/state/mise" 0];
      antigravity-bin-deadlinks = [".antigravity/antigravity/bin" 0];
      claude-debug-dead-pointer = [".claude/debug" 1];
    };
    # Agent-root retention: material younger than the window is never a
    # candidate, so a live session's working files stay untouchable.
    age = {
      claude-backups-retention = [".claude/backups" 14 ""];
      claude-file-history-retention = [".claude/file-history" 30 ""];
      claude-session-env-retention = [".claude/session-env" 14 ""];
      claude-tasks-retention = [".claude/tasks" 30 ""];
      codex-dot-tmp-retention = [".codex/.tmp" 14 ""];
      codex-tmp-retention = [".codex/tmp" 7 ""];
      codex-sessions-retention = [".codex/sessions" 60 ""];
      codex-archived-sessions-retention = [".codex/archived_sessions" 60 ""];
      codex-attachments-retention = [".codex/attachments" 30 ""];
      codex-previous-binary = [".local/bin" 14 "codex.previous"];
    };
    # Stale trusted-project rows (nonexistent paths, scratch-class prefixes)
    # leave config.toml; durable repo rows stay.
    codex-trust.codex-trusted-projects = ".codex/config.toml";
    # Storage-pressure ledger: budget, owner, prune command as data —
    # report-only, never auto-deleted.
    ledger = {
      ledger-colima = [".local/share/colima" 100 "environments/containers.nix" "colima delete / docker system prune"];
      ledger-colima-cache = [".cache/colima" 3 "environments/containers.nix" "colima prune cached images"];
      ledger-uv-cache = [".cache/uv" 30 "uv" "uv cache prune"];
      ledger-uv-runtimes = [".local/share/uv" 2 "uv" "uv python uninstall <superseded>"];
      ledger-nuget-root = [".nuget" 20 "dotnet" "dotnet nuget locals all --clear"];
      ledger-nuget-xdg = [".local/share/NuGet" 8 "dotnet" "dotnet nuget locals http-cache --clear"];
      ledger-gemini = [".gemini" 5 "antigravity" "operator: clear browser_recordings trees"];
      ledger-antigravity = [".antigravity" 3 "antigravity" "operator: dedupe extension versions"];
      ledger-python-envs = [".local/state/forge-python-envs" 5 "languages/scientific-tools.nix" "forge-scientific-sync"];
      ledger-pnpm-store = [".local/share/pnpm" 4 "environments/languages.nix" "pnpm store prune"];
      ledger-pnpm-cache = [".cache/pnpm" 2 "environments/languages.nix" "pnpm store prune"];
      ledger-claude-root = [".claude" 4 "agent-root retention rows" "forge-cleanup apply (age rows)"];
      ledger-codex-root = [".codex" 3 "agent-root retention rows" "forge-cleanup apply (age rows)"];
      ledger-grype-db = [".cache/grype" 3 "grype" "grype db delete"];
      ledger-codex-runtimes = [".cache/codex-runtimes" 3 "codex" "trash after a codex update proves clean"];
      ledger-pulumi-plugins = [".pulumi" 2 "services/ provider pins" "pulumi plugin rm --all; reinstall pinned"];
      ledger-rhinocode = [".rhinocode" 2 "rhino AEC lane" "operator"];
      ledger-npm-global = [".local/share/npm" 1 "pnpm-only law" "collapse remaining globals onto pnpm"];
      ledger-forge-mcp-cache = [".cache/forge-mcp" 1 "shell-tools/mcp-fleet.nix" "trash; launchers rebuild on next start"];
      ledger-docker-root-dot = [".docker" 1 "environments/containers.nix" "deadlink row + endpoint-truth adjudication"];
      ledger-xdg-trash = [".local/share/Trash" 2 "trash-first cleanup law" "operator empties Trash"];
      ledger-nix-eval-cache = [".cache/nix" 3 "determinate-nixd" "trash eval/tarball caches; regenerated"];
      ledger-claude-desktop = ["Library/Application Support/Claude" 30 "Claude Desktop app" "operator: app-managed state"];
      ledger-duckdb-root = [".duckdb" 1 "duckdb catalog owner" "relocation adjudicated with the catalog owner first"];
    };
    # Named decisions, receipt-only; a row closes by gaining an owner or a
    # consumer. secret-custody rows report key-name-only, never values.
    adjudicate = {
      ccstatusline-config = [".config/ccstatusline" "retention-ignore" "app-owned statusline state"];
      kube-config-target = [".config/kube" "pending-consumer" "declared KUBECONFIG target absent; closes when a cluster lands"];
      homebrew-trust-db = [".config/homebrew/trust.json" "keep" "live Homebrew 6 trust DB; placement re-adjudication open"];
      homebrew-root-dot-trust = [".homebrew" "open" "split trust state; collapse rides homebrew ownership re-adjudication"];
      jgit-probe-state = [".config/jgit" "retention-ignore" "host-probe cache; regrows on JGit use"];
      claude-desktop-config = ["Library/Application Support/Claude/claude_desktop_config.json" "registry-candidate" "joins the five-way MCP registration drift when the generator lands"];
      vscode-extensions-root = [".vscode" "keep" "live VS Code extension estate; manifest extension lane owns admission"];
      cloudstorage-variant-roots = ["Library/CloudStorage" "operator-disposal" "stale GoogleDrive account-variant roots; FileProvider-managed, never bulk-trashed"];
      sqlean-unmanaged-dylibs = [".local/share/sqlean" "operator-disposal" "unmanaged copies; live owner overlays/sqlean + sqlite-forge"];
      jupyter-root-dot = [".jupyter" "relocation-pending" "forge-jupyter probe family owns live state"];
      secret-custody-gcloud = [".config/gcloud" "custody-row" "credential DBs under config; key-name-only receipts"];
      secret-custody-gws = [".config/gws" "custody-row" "token cache + client secret under config"];
      secret-custody-op-session = [".config/hm-op-session.sh" "custody-row" "generated literal-token file; owner shell-tools/1password.nix"];
      secret-custody-jupyter-token = [".config/jupyter/forge-token.env" "custody-row" "literal JUPYTER_TOKEN; owner languages/scientific-tools.nix"];
      secret-custody-gh-hosts = [".config/gh/hosts.yml" "custody-row" "live gh auth state; ssh-doctor custody, never an HM target"];
      codex-browser-authority = [".codex/browser/config.toml" "declared" "never_ask + full CDP ride the operator full-authority grant"];
      harness-policy-drift = [".claude/settings.json" "receipted" "declared bypassPermissions vs live enforcement; receipt per root"];
      rasm-bridge-state = [".rasm" "relocation-pending" "rhino-bridge lease/quit journals in a home root dotdir; relocation rides the bridge owner in Rasm"];
    };
    # kill rows are the evidence-gated reap set; report rows keep
    # daemon-by-design classes (git fsmonitor, op) visible without lifecycle
    # theft. codex lanes detach by design; only lanes far past every
    # effort-tier deadline are litter. node-modules census is the visibility
    # net for new daemon classes before they earn a kill row.
    orphan = {
      biome-lsp-proxy-orphans = ["biome lsp-proxy" "" 300 "kill"];
      biome-daemon-orphans = ["biome __run_server" "" 300 "kill"];
      mcp-fleet-orphans = ["[.]cache/forge-mcp/" "" 300 "kill"];
      mcp-uv-orphans = ["(postgres-mcp|workspace-mcp|jupyter-mcp|notebooklm-mcp|ifcmcp|nuget-mcp)" "" 300 "kill"];
      rhino-router-orphans = ["rhino-mcp-router" "" 300 "kill"];
      lsp-server-orphans = ["(tsgo --lsp|bash-language-server|yaml-language-server|lua-language-server|(^|/)nixd|dts-lsp|postgrestools|roslyn-language-server|Microsoft[.]CodeAnalysis[.]LanguageServer|(^|/)ty server)" "" 300 "kill"];
      csharp-buildhost-orphans = ["(BuildHost-netcore|MSBuild[.]BuildHost[.]dll)" "" 600 "kill"];
      forge-edit-nvim-orphans = ["nvim.*(forge-edit|forge-accept)" "" 1800 "kill"];
      codex-lane-orphans = ["(^|/)codex (exec|e) " "Codex[.]app" 14400 "kill"];
      git-fsmonitor-census = ["fsmonitor--daemon" "" 604800 "report"];
      op-daemon-census = ["(^|/)op daemon" "" 86400 "report"];
      node-modules-daemon-census = ["/node_modules/" "biome" 3600 "report"];
    };
  }));

  # Guarded cleanup rail: `plan` emits a durable precheck receipt, `apply`
  # executes only rows the plan proved safe, re-verified at act time and
  # trash-first, so every deletion stays recoverable from ~/.Trash. `sweep`
  # is the orphan lane: fresh detection plus evidence-gated reaping of
  # ppid-1 agent-lane processes, one receipt row per pid.
  forgeCleanup = mkTool {
    name = "forge-cleanup";
    receiptName = "forge-orphan-sweep";
    inputs = [pkgs.coreutils pkgs.findutils pkgs.gawk pkgs.jq];
    text = ''
      rows_json='${cleanupRows}'
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/forge-cleanup"
      run_ts="''${ts//[-:]/}"
      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT
      usage() { echo "usage: forge-cleanup plan | apply [plan-file] | sweep [--report-only]" >&2; exit 64; }
      verb="''${1:-}"; shift || true

      # Hard deny for the kill lane: session servers, GUI apps, credential
      # daemons, and system trees are never reaped even on a class match.
      deny_re='/System/|/Applications/|zellij|[Ww]ez[Tt]erm|1[Pp]assword|[Cc]rashpad|loginwindow|(^|/)ssh'
      # Trust rows on scratch/transient roots are litter by class; durable
      # repo rows never match this and always survive the prune.
      scratch_re="^(/private/tmp/|/tmp/|$HOME/Downloads(/|$)|$HOME/Library/CloudStorage/)"

      # One live snapshot per run: uid-owned, ppid-1, tty-less processes with
      # age in seconds and RSS KiB; launchd-managed pids drop out first, so a
      # sanctioned agent (KeepAlive services included) is never a candidate.
      proc_snapshot() {
        if [ ! -e "$work/procs" ]; then
          /bin/launchctl list 2>/dev/null | awk 'NR > 1 && $1 ~ /^[0-9]+$/ {print $1}' >"$work/managed"
          /bin/ps -axo pid=,ppid=,uid=,tty=,etime=,rss=,command= 2>/dev/null | awk -v uid="$(id -u)" -v self="$$" '
            function esecs(e,  a, n, d, hms) {
              d = 0
              if (index(e, "-") > 0) { split(e, a, "-"); d = a[1]; e = a[2] }
              n = split(e, hms, ":")
              if (n == 3) return ((d * 24 + hms[1]) * 60 + hms[2]) * 60 + hms[3]
              if (n == 2) return (d * 24 * 60 + hms[1]) * 60 + hms[2]
              return hms[1] + 0
            }
            NR == FNR { managed[$1] = 1; next }
            $2 == 1 && $3 == uid && $4 == "??" && !($1 in managed) && $1 != self {
              cmd = ""
              for (i = 7; i <= NF; i++) cmd = cmd (i > 7 ? " " : "") $i
              printf "%s\t%s\t%s\t%s\n", $1, esecs($5), $6, cmd
            }
          ' "$work/managed" - >"$work/procs"
        fi
        cat "$work/procs"
      }

      # args: match exclude min-age action. Deny applies to the kill lane
      # only; report rows keep daemon-by-design classes visible.
      orphan_matches() {
        proc_snapshot | awk -F '\t' -v m="$1" -v x="$2" -v g="$3" -v a="$4" -v d="$deny_re" '
          $2 >= g && $4 ~ m && (x == "" || $4 !~ x) && (a != "kill" || $4 !~ d) {print}'
      }

      # TERM, bounded wait, KILL residue.
      reap_pid() {
        kill -TERM "$1" 2>/dev/null || return 1
        for _ in 1 2 3; do
          kill -0 "$1" 2>/dev/null || return 0
          sleep 1
        done
        kill -KILL "$1" 2>/dev/null || true
      }

      # Shared reap/report emitter for apply and sweep: $5 is the row action
      # (deny-lane gate), $6 the behavior this run applies (kill|report).
      reap_matches() { # name match exclude minage row-action act
        reaped=0
        while IFS=$'\t' read -r opid oage orss ocmd; do
          if [ "$6" = kill ]; then
            if reap_pid "$opid"; then
              reaped=$((reaped + 1))
              printf '%s\tkilled\tpid=%s\tage_s=%s\trss_kb=%s\tcmd=%.140s\n' "$1" "$opid" "$oage" "$orss" "$ocmd"
            else
              printf '%s\tgone\tpid=%s\n' "$1" "$opid"
            fi
          else
            printf '%s\treport\tpid=%s\tage_s=%s\trss_kb=%s\tcmd=%.140s\n' "$1" "$opid" "$oage" "$orss" "$ocmd"
          fi
        done < <(orphan_matches "$2" "$3" "$4" "$5")
      }

      # One jq projection per row: every field lands in one read. Unit-separator
      # delimited: tab is IFS whitespace and read would collapse empty fields.
      row_fields() {
        jq -r '[.name, .kind, (.target // ""), (.expect // ""), (.root // ""), (.pattern // ""), (.match // ""), (.exclude // ""), (.minAgeSec // 0 | tostring), (.action // ""), (.depth // 0 | tostring), (.maxAgeDays // 0 | tostring), (.budgetGb // 0 | tostring), (.owner // ""), (.prune // ""), (.decision // ""), (.note // "")] | join("\u001f")' <<<"$1"
      }

      # One NUL-emitting candidate enumerator per find-shaped kind; detect and
      # apply consume the same predicates, so lane drift is unspellable.
      candidates() { # kind root pattern depth maxAgeDays
        local -a args=()
        [ "$4" = 0 ] || args+=(-maxdepth "$4")
        case "$1" in
          glob) args+=(-mindepth 1 -name "$3" -prune) ;;
          age)
            args+=(-mindepth 1 -type f)
            [ -z "$3" ] || args+=(-name "$3")
            args+=(-mtime "+$5")
            ;;
          deadlink) args+=(-type l ! -exec test -e "{}" ";") ;;
        esac
        find "$2" "''${args[@]}" -print0 2>/dev/null
      }
      count0() { tr -cd '\0' | wc -c | tr -d ' '; }
      sum_kb0() { xargs -0 du -sk 2>/dev/null | awk '{s += $1} END {print s + 0}'; }

      # Stale trusted-project extraction: a row is stale when its path no
      # longer exists or sits on a scratch-class prefix.
      codex_stale_projects() {
        local p
        while IFS= read -r p; do
          if [ ! -e "$p" ] || [[ "$p" =~ $scratch_re ]]; then printf '%s\n' "$p"; fi
        done < <(gawk 'match($0, /^\[projects\."(.*)"\]$/, m) {print m[1]}' "$1")
      }

      # One detector owns every row kind; plan and apply both consume it, so
      # apply never acts on a state the detector cannot reproduce live.
      detect_row() {
        local row="$1" name kind state count kb action safe detail target expect root pattern current match exclude minage oaction opid orss pidlist depth maxage budget owner prune decision note cfg budget_kb
        IFS=$'\x1f' read -r name kind target expect root pattern match exclude minage oaction depth maxage budget owner prune decision note < <(row_fields "$row")
        state=clean count=0 kb=0 action=none safe=true detail=-
        case "$kind" in
          mode)
            target="$HOME/$target"
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
            target="$HOME/$target"
            if [ -L "$target" ]; then
              state=review safe=false detail="symlink, not a residue tree"
            elif [ -e "$target" ]; then
              state=litter action=trash count=1
              kb="$(du -sk "$target" 2>/dev/null | cut -f1 || echo 0)"
            fi
            ;;
          glob | age | deadlink)
            root="$HOME/$root"
            if [ -d "$root" ]; then
              count="$(candidates "$kind" "$root" "$pattern" "$depth" "$maxage" | count0)"
              if [ "$count" -gt 0 ]; then
                state=litter
                case "$kind" in
                  glob) action=trash ;;
                  age) action=trash-aged detail="age>''${maxage}d" ;;
                  deadlink) action=trash-links ;;
                esac
                [ "$kind" = deadlink ] || kb="$(candidates "$kind" "$root" "$pattern" "$depth" "$maxage" | sum_kb0)"
              fi
            fi
            ;;
          ledger)
            target="$HOME/$target"
            safe=false
            if [ -e "$target" ]; then
              kb="$(du -sk "$target" 2>/dev/null | cut -f1 || echo 0)"
              budget_kb=$((budget * 1024 * 1024))
              if [ "''${kb:-0}" -gt "$budget_kb" ]; then state=over-budget; else state=within-budget; fi
              detail="owner=$owner budget=''${budget}G prune: $prune"
            else
              state=absent detail="owner=$owner"
            fi
            ;;
          adjudicate)
            safe=false state=adjudicated
            { [ -e "$HOME/$target" ] || [ -L "$HOME/$target" ]; } || state=absent
            detail="decision=$decision; $note"
            ;;
          codex-trust)
            cfg="$HOME/$target"
            if [ -f "$cfg" ]; then
              detail="$(codex_stale_projects "$cfg" | paste -sd' ' -)"
              count="$(codex_stale_projects "$cfg" | wc -l | tr -d ' ')"
              if [ "$count" -gt 0 ]; then
                state=litter action=prune-trust detail="stale: $detail"
              else
                detail=-
              fi
            fi
            ;;
          orphan)
            pidlist=""
            while IFS=$'\t' read -r opid _ orss _; do
              count=$((count + 1))
              kb=$((kb + orss))
              pidlist="$pidlist,$opid"
            done < <(orphan_matches "$match" "$exclude" "$minage" "$oaction")
            if [ "$count" -gt 0 ]; then
              if [ "$oaction" = kill ]; then
                state=litter action=kill detail="pids=''${pidlist#,}"
              else
                state=review safe=false detail="pids=''${pidlist#,}"
              fi
            fi
            ;;
        esac
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$kind" "$state" "$count" "$kb" "$action" "$safe" "$detail"
      }

      trash() {
        mkdir -p "$HOME/.Trash"
        local dest="$HOME/.Trash/''${1##*/}.forge-cleanup.$run_ts"
        # Basename collisions from deep-tree prunes get a unique suffix so no
        # candidate silently stays behind.
        while [ -e "$dest" ] || [ -L "$dest" ]; do dest="$dest.$RANDOM"; done
        mv -- "$1" "$dest"
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
            IFS=$'\x1f' read -r _ row_kind row_target _ row_root row_pattern row_match row_exclude row_minage _ row_depth row_maxage _ _ _ _ _ < <(row_fields "$row")
            # Re-verify at act time: a row that drifted since plan is skipped.
            fresh_state="$(detect_row "$row" | cut -f3)"
            if [ "$fresh_state" != litter ]; then
              printf '%s\taction=none\toutcome=drifted-%s\n' "$name" "$fresh_state"
              continue
            fi
            case "$action" in
              chmod-*)
                chmod "''${action#chmod-}" "$HOME/$row_target"
                printf '%s\taction=%s\toutcome=applied\n' "$name" "$action"
                ;;
              trash | trash-aged | trash-links)
                moved=0
                if [ "$row_kind" = path ]; then
                  trash "$HOME/$row_target"
                  moved=1
                else
                  while IFS= read -r -d "" match; do
                    trash "$match"
                    moved=$((moved + 1))
                  done < <(candidates "$row_kind" "$HOME/$row_root" "$row_pattern" "$row_depth" "$row_maxage")
                fi
                printf '%s\taction=%s\toutcome=applied\tcount=%s\n' "$name" "$action" "$moved"
                ;;
              prune-trust)
                cfg="$HOME/$row_target"
                stale_list="$work/codex-stale"
                codex_stale_projects "$cfg" >"$stale_list"
                if [ -s "$stale_list" ]; then
                  # Backup rides the trash rail like every other mutation.
                  cp -p "$cfg" "$work/config.toml.pre-prune" && trash "$work/config.toml.pre-prune"
                  gawk '
                    NR == FNR { stale[$0] = 1; next }
                    {
                      if (match($0, /^\[projects\."(.*)"\]$/, m)) drop = (m[1] in stale)
                      else if ($0 ~ /^\[/) drop = 0
                      if (!drop) print
                    }
                  ' "$stale_list" "$cfg" >"$cfg.forge-prune" && mv "$cfg.forge-prune" "$cfg"
                  printf '%s\taction=prune-trust\toutcome=applied\tcount=%s\n' "$name" "$(wc -l <"$stale_list" | tr -d ' ')"
                else
                  printf '%s\taction=prune-trust\toutcome=drifted-clean\n' "$name"
                fi
                ;;
              kill)
                reap_matches "$name" "$row_match" "$row_exclude" "$row_minage" kill kill
                printf '%s\taction=kill\toutcome=applied\tcount=%s\n' "$name" "$reaped"
                ;;
              *)
                printf '%s\taction=%s\toutcome=unknown-action\n' "$name" "$action"
                ;;
            esac
          done <"$plan_file"
        } | tee "$apply_file"
        printf 'forge-cleanup: apply receipt %s\n' "$apply_file"
      }

      # Orphan-only lane for the scheduled agent: fresh detection each run,
      # kill rows reaped, report rows logged; per-pid receipt plus one
      # summary line on the receipts log.
      cmd_sweep() {
        report_only=0
        [ "''${1:-}" != "--report-only" ] || report_only=1
        mkdir -p "$state_dir"
        sweep_file="$state_dir/sweep-$run_ts.tsv"
        {
          printf '# forge-cleanup sweep\tts=%s\treport_only=%s\n' "$run_ts" "$report_only"
          while IFS= read -r row; do
            IFS=$'\x1f' read -r name kind _ _ _ _ match exclude minage oaction < <(row_fields "$row")
            [ "$kind" = orphan ] || continue
            act="$oaction"
            [ "$report_only" = 0 ] || act=report
            reap_matches "$name" "$match" "$exclude" "$minage" "$oaction" "$act"
          done < <(jq -c '.[]' "$rows_json")
        } >"$sweep_file"
        cat "$sweep_file"
        read -r killed reported gone < <(awk -F '\t' 'NR > 1 {c[$2]++} END {printf "%d %d %d\n", c["killed"] + 0, c["report"] + 0, c["gone"] + 0}' "$sweep_file")
        persist_receipt "$(printf 'ts=%s\tkilled=%s\treported=%s\tgone=%s\treport_only=%s\treceipt=%s\tresult=ok' \
          "$run_ts" "$killed" "$reported" "$gone" "$report_only" "$sweep_file")"
      }

      case "$verb" in
        plan) cmd_plan ;;
        apply) cmd_apply "$@" ;;
        sweep) cmd_sweep "$@" ;;
        *) usage ;;
      esac
    '';
  };

  # Daily currency rail: flake-input bump plus declared-vs-deployed detection.
  # Builds run through forge-redeploy --build, so receipts, flock, and cache
  # push stay single-owner; a landed bump auto-commits (operator ruling: full
  # automation, no branches) and never switches unattended.
  forgeNixDrift = mkTool {
    name = "forge-nix-drift";
    storePath = true;
    inputs = [pkgs.coreutils pkgs.git pkgs.jq pkgs.gnugrep pkgs.gawk pkgs.flock forgeRedeploy];
    text = ''
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
      lock_file="''${FORGE_NIX_DRIFT_LOCK:-$HOME/.cache/forge-nix-drift.lock}"

      # One typed receipt per run; the EXIT trap emits it even when a phase
      # aborts, so failed bumps and builds stay visible (result=fail).
      power="-" lock="-" worktree="-" inputs="-" bump="-"
      build="-" commit="-" deployed="-" nixd="-"
      result="fail"
      emit_receipt() {
        persist_receipt "$(printf 'ts=%s\tmode=%s\tpower=%s\tlock=%s\tworktree=%s\tinputs=%s\tbump=%s\tbuild=%s\tcommit=%s\tdeployed=%s\tnixd=%s\tresult=%s' \
          "$ts" "$mode" "$power" "$lock" "$worktree" "$inputs" "$bump" \
          "$build" "$commit" "$deployed" "$nixd" "$result")"
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
      exec {lock_fd}>"$lock_file"
      flock "''${flock_args[@]}" "$lock_fd" || {
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
  # a prior generation blocks the user-mode backup/relink during activation;
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

  # Pre-activation guard for the gen-810 class: detect root-owned in-the-way
  # HM targets, clear them in one sudo batch, prove the clear with a receipt.
  forgeActivationSweep = mkTool {
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

  # First-switch and first-session acceptance choreography: one ordered,
  # receipt-bearing rail from preflight through the maghz codex gate, idempotent
  # and re-enterable from any step (--from/--only). Probes stay thread-owned
  # (forge-redeploy receipts, forge-terminal-accept, forge-mcp doctor); this
  # owner orders and asserts. Key material is asserted by NAME only, never value.
  forgeAccept = mkTool {
    name = "forge-accept";
    inputs = [pkgs.coreutils pkgs.gnugrep pkgs.gawk pkgs.jq pkgs.findutils pkgs.lsof pkgs.zellij pkgs.flock forgeActivationSweep forgeRedeploy];
    text = ''
      declare -ra STEPS=(preflight switch replay outputs zellij terminal fleet lanes maghz relaunch)
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
        printf '%s\n' "''${STEPS[@]}" | grep -qx "''${from:-$only}" || usage
      fi

      uid="$(id -u)"
      forge_root="''${FORGE_ROOT:-$HOME/Documents/99.Github/Parametric_Forge}"
      custom_conf="/etc/nix/nix.custom.conf"
      lock_file="''${FORGE_REDEPLOY_LOCK:-$HOME/.cache/forge-redeploy.lock}"
      cache_home="''${XDG_CACHE_HOME:-$HOME/.cache}"
      config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
      session_cache="$cache_home/forge-secrets/session-env.sh"
      gui_manifest="$cache_home/forge-secrets/gui-replay.names"
      brew_bin="''${FORGE_BREW:-/opt/homebrew/bin/brew}"
      hook="''${FORGE_ACCEPT_HOOK:-$HOME/.claude/hooks/setup-env.sh}"
      tunnel_receipts="''${FORGE_TUNNEL_RECEIPTS:-$HOME/Library/Logs/forge-maghz-vps-tunnel.receipts.log}"
      pass=0 warn=0 fail=0 instruct=0 skip=0

      row() {
        printf 'ts=%s\tstep=%s\tstatus=%s\tdetail=%s\n' "$ts" "$2" "$1" "$3" >>"$receipt_log"
        printf '%-8s | %-22s | %s\n' "$1" "$2" "$3" >&2
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
        grep -oE '^export [A-Za-z_][A-Za-z0-9_]*' "$1" | awk '{print $2}'
      }
      # GUI-domain env NAMES only: values are stripped before anything prints;
      # launchctl getenv false-negatives make raw print the only truthful read.
      gui_names() {
        /bin/launchctl print "gui/$uid" 2>/dev/null \
          | awk '/^\tenvironment = \{/ {f = 1; next} f && /^\t\}/ {exit} f {sub(/^\t\t/, ""); sub(/ =>.*/, ""); print}'
      }
      expected_names() {
        key_names "$session_cache" | sort -u
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
        ! grep -qx 'wezterm@nightly' <<<"$casks" || nightly="installed"
        ! grep -qx 'wezterm' <<<"$casks" || stable="installed"
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
        # Clean-env INTERACTIVE login shell: the terminal lane. typeset -U
        # dedup lives in .zshrc, which non-interactive login shells skip, and
        # an inherited caller PATH would fake duplicate segments.
        local path_out dup
        # shellcheck disable=SC2016  # $PATH expands inside the probed zsh, not here.
        path_out="$(env -i HOME="$HOME" USER="$USER" LOGNAME="$USER" SHELL=/bin/zsh TERM=xterm \
          /bin/zsh -il -c 'printf %s "$PATH"' 2>/dev/null || true)"
        dup="$(tr ':' '\n' <<<"$path_out" | grep -v '^$' | sort | uniq -d | paste -sd' ' -)"
        if [ -n "$path_out" ] && [ -z "$dup" ] && grep -q "/etc/profiles/per-user/" <<<"$path_out"; then
          row PASS outputs-path "login PATH single-owner: per-user profile present, no duplicate segments"
        else
          row FAIL outputs-path "dup segments: ''${dup:-none}; per-user profile $(grep -q '/etc/profiles/per-user/' <<<"$path_out" && echo present || echo ABSENT)"
        fi
        if [ -L "$config_home/zsh/.zshrc" ] && [[ "$(readlink "$config_home/zsh/.zshrc")" == /nix/store/* ]]; then
          row PASS outputs-zshrc "generated .zshrc is store-linked"
        else
          row FAIL outputs-zshrc ".zshrc is not a store symlink; the generation did not land"
        fi
        local dumps
        dumps="$(find "$config_home/zsh" -maxdepth 1 -name '.zcompdump*' 2>/dev/null | wc -l | tr -d ' ')"
        if [ "$dumps" = 0 ]; then
          row PASS outputs-compdump "no compdump litter in ZDOTDIR"
        else
          row WARN outputs-compdump "$dumps .zcompdump file(s) in ZDOTDIR; forge-cleanup plan/apply clears them"
        fi
        # Background-limited agents (LimitLoadToSessionType) address as
        # user/$uid; plain gui agents as gui/$uid — probe both domains.
        if { /bin/launchctl print "user/$uid/org.nix-community.home.atuin-daemon" \
          || /bin/launchctl print "gui/$uid/org.nix-community.home.atuin-daemon"; } 2>/dev/null \
          | grep -q 'state = running'; then
          row PASS outputs-atuin "atuin daemon agent running"
        else
          row FAIL outputs-atuin "atuin daemon agent not running"
        fi
        local zwarn
        zwarn="$(/bin/zsh -il -c 'exit 0' 2>&1 | grep -i 'fzf' | head -1 || true)"
        if [ -z "$zwarn" ]; then
          row PASS outputs-fzf "interactive zsh emits no fzf width warnings"
        else
          row FAIL outputs-fzf "fzf warning: $zwarn"
        fi
      }

      # Server-respawn legality: a zellij server inherits its spawner's env, so
      # a server predating the live generation serves stale session variables.
      # Respawn is legal ONLY for forge-owned sessions with zero attached
      # clients; user sessions get an instruction row — only WezTerm (launchd
      # env) may spawn the replacement server, never an agent shell.
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
          pid="$(pgrep -f -- "zellij.*--server .*/''${name}\$" | head -1 || true)"
          start=0
          if [ -n "$pid" ]; then
            lstart="$(ps -o lstart= -p "$pid" 2>/dev/null || true)"
            [ -z "$lstart" ] || start="$(date -d "$lstart" +%s 2>/dev/null || echo 0)"
          fi
          attached="$(zellij --session "$name" action list-clients 2>/dev/null | tail -n +2 | wc -l | tr -d ' ' || echo 0)"
          if [ "''${start:-0}" != 0 ] && [ "$start" -ge "$sys_epoch" ]; then
            row PASS zellij-respawn "session '$name' server postdates the live generation (clients=''${attached:-0})"
          elif [[ "$name" == forge-accept-* ]] && [ "''${attached:-0}" = 0 ]; then
            zellij kill-session "$name" >/dev/null 2>&1 || true
            zellij delete-session "$name" >/dev/null 2>&1 || true
            row PASS zellij-respawn "disposable '$name' (stale server) reaped; respawn legal: forge-owned, zero clients"
          else
            row INSTRUCT zellij-respawn "session '$name' server predates the live generation (clients=''${attached:-0}); close it and relaunch from WezTerm — respawn is legal only at zero attached clients, and only WezTerm may spawn the server"
          fi
        done <<<"$sessions"
      }

      step_terminal() {
        command -v forge-terminal-accept.sh >/dev/null 2>&1 || {
          row SKIP terminal "forge-terminal-accept.sh not on PATH"
          return 0
        }
        local out rc=0 p f d
        out="$(forge-terminal-accept.sh 2>/dev/null)" || rc=$?
        p="$(jq -r '.summary.pass // 0' <<<"$out" 2>/dev/null || echo 0)"
        f="$(jq -r '.summary.fail // 0' <<<"$out" 2>/dev/null || echo 0)"
        d="$(jq -r '.summary.defer // 0' <<<"$out" 2>/dev/null || echo 0)"
        if [ "$rc" = 0 ] && [ "''${f:-1}" = 0 ]; then
          row PASS terminal "keystone harness pass=$p defer=$d (deferred rows run in the attached leg)"
        else
          row FAIL terminal "keystone harness rc=$rc pass=$p fail=$f defer=$d"
        fi
      }

      step_fleet() {
        command -v forge-mcp >/dev/null 2>&1 || {
          row SKIP fleet-doctor "forge-mcp not on PATH"
          return 0
        }
        local out rc=0 drc=0
        out="$(forge-mcp doctor --network 2>&1)" || rc=$?
        if [ "$rc" = 0 ]; then
          row PASS fleet-doctor "all probed fleet rows green"
        else
          row FAIL fleet-doctor "failing rows: $(grep '^\[FAIL\]' <<<"$out" | awk '{print $2}' | paste -sd' ' - || true)"
        fi
        forge-mcp drift >/dev/null 2>&1 || drc=$?
        if [ "$drc" = 0 ]; then
          row PASS fleet-drift "manifest matches both client registrations"
        else
          row FAIL fleet-drift "registration drift; run forge-mcp drift"
        fi
      }

      step_lanes() {
        local expected tmp cli_names cli_missing tui_missing gui_missing
        expected="$(expected_names)"
        [ -n "$expected" ] || {
          row WARN lanes "no session material on disk; run a Claude session first"
          return 0
        }
        tmp="$(mktemp -d)"
        CLAUDE_ENV_FILE="$tmp/env.sh" bash "$hook" >/dev/null 2>"$tmp/receipt" || true
        cli_names="$(key_names "$tmp/env.sh" | sort -u)"
        cli_missing="$(comm -23 <(printf '%s\n' "$expected") <(printf '%s\n' "$cli_names") | paste -sd' ' -)"
        tui_missing="$(ZKEYS="$(paste -sd' ' - <<<"$expected")" /bin/zsh -il -c \
          'for k in ''${(s: :)ZKEYS}; do [ -n "''${(P)k}" ] || print "$k"; done' 2>/dev/null | paste -sd' ' -)"
        gui_missing="$(comm -23 <(printf '%s\n' "$expected") <(gui_names | sort -u) | paste -sd' ' -)"
        rm -rf "$tmp"
        if [ -z "$cli_missing$tui_missing$gui_missing" ]; then
          row PASS lanes "cli/tui/gui all carry the expected key-name set ($(wc -l <<<"$expected" | tr -d ' ') names)"
        else
          row FAIL lanes "missing — cli:[''${cli_missing}] tui:[''${tui_missing}] gui:[''${gui_missing}]"
        fi
      }

      # Holder classification separates routine (colima local-parity mode)
      # from regression (a shared ssh mux retaining tunnel forwards).
      classify_holder() {
        local cmd
        cmd="$(ps -o command= -p "$1" 2>/dev/null || true)"
        case "$cmd" in
          *colima* | *lima*) echo colima ;;
          *ssh*) echo ssh-mux ;;
          *) echo other ;;
        esac
      }

      step_maghz() {
        local last state kinds
        last="$(tail -1 "$tunnel_receipts" 2>/dev/null || true)"
        [ -n "$last" ] || {
          row WARN maghz "no tunnel receipts at $tunnel_receipts"
          return 0
        }
        state="$(grep -oE 'state=[a-z-]+' <<<"$last" | cut -d= -f2 || true)"
        case "$state" in
          up)
            row PASS maghz "tunnel up: ''${last#*state=up}"
            ;;
          port-conflict)
            local -a cports=()
            read -ra cports <<<"$(grep -oE 'spawn:[0-9 ]+' <<<"$last" | cut -d: -f2 || true)"
            kinds="$(for p in "''${cports[@]}"; do
              lsof -nP -iTCP:"$p" -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $2}'
            done | sort -u | while IFS= read -r hpid; do classify_holder "$hpid"; done | sort -u | paste -sd' ' -)"
            case "$kinds" in
              *ssh-mux*)
                row FAIL maghz "port-conflict regression: a shared ssh ControlMaster retains the forwards; exit the mux (ssh -O exit maghz) — ControlPath=none on the tunnel host prevents recurrence"
                ;;
              colima)
                row WARN maghz "port-conflict routine: local compose parity mode holds the forwards; boot the tunnel agent out while local mode runs"
                ;;
              *)
                row WARN maghz "port-conflict: holder kinds=''${kinds:-unknown}"
                ;;
            esac
            ;;
          *)
            row WARN maghz "tunnel state=''${state:-unknown}: ''${last#*state=}"
            ;;
        esac
        if [ "$state" = "up" ]; then
          row PASS maghz-codex "tunnel up; codex-required postgres MCP startup gate clear"
        else
          row INSTRUCT maghz-codex "postgres MCP is codex-required: codex startup hard-fails while the tunnel is ''${state:-down}; sequence tunnel-up (or local compose with a repointed DSN) before launching codex"
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

  # ~/.local/bin admission-or-removal decisions: every unmanaged entry carries
  # a named ruling; an entry absent from this table reports unadjudicated.
  localBinDecisions = pkgs.writeText "forge-path-doctor-decisions.json" (builtins.toJSON {
    claude = "admitted: launcher symlink into the versioned install";
    codex = "admitted-agent: unmanaged binary; manifest admission row open";
    "codex.previous" = "retention: self-update backup; aged out by forge-cleanup";
    coderabbit = "reviewer-identity: unmanaged reviewer binary (services matrix)";
    cr = "reviewer-identity: symlink to coderabbit";
    greptile = "reviewer-identity: launcher";
    "greptile.js" = "reviewer-identity: bundle";
    agy = "admitted-agent: antigravity CLI";
    "pre-commit" = "uv-lane: uv tool shim";
    "pynvim-python" = "uv-lane: uv tool shim";
    "python3.12" = "uv-lane: uv runtime shim";
    "python3.14" = "uv-lane: uv runtime shim";
    tree = "hm: generation link";
    loc = "hm: generation link";
  });

  # PATH and binary provenance doctor: owner classification per PATH segment,
  # cross-owner shadow detection on resolved targets, the file/MAGIC seed
  # case, CLT health, brew posture, and the ~/.local/bin decision inventory.
  # Read-only; one receipt line per run.
  forgePathDoctor = mkTool {
    name = "forge-path-doctor";
    inputs = [pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.gawk pkgs.jq];
    text = ''
      shadows=0 mismatches=0 unadjudicated=0
      brew_bin="''${FORGE_BREW:-/opt/homebrew/bin/brew}"

      owner_of() {
        case "$1" in
          /etc/profiles/per-user/* | "$HOME/.nix-profile"*) echo hm ;;
          /run/current-system/*) echo system ;;
          /nix/*) echo nix ;;
          /opt/homebrew/*) echo homebrew ;;
          "$HOME/.local/bin"*) echo local ;;
          /usr/bin/* | /bin/* | /usr/sbin/* | /sbin/* | /usr/libexec/*) echo macos ;;
          /Applications/* | "$HOME/Applications"*) echo app ;;
          *) echo unknown ;;
        esac
      }

      # %b: payload fields carry embedded \t separators.
      row() { printf 'ts=%s\tfamily=%s\t%b\n' "$ts" "$1" "$2"; }

      # Cross-owner shadow scan: a later PATH segment holding a DIFFERENT
      # binary under a DIFFERENT owner class than the winning segment.
      declare -A win
      IFS=: read -ra segs <<<"$PATH"
      for d in "''${segs[@]}"; do
        [ -d "$d" ] || continue
        for f in "$d"/*; do
          [ -x "$f" ] || continue
          n="''${f##*/}"
          if [ -z "''${win[$n]:-}" ]; then
            win[$n]="$f"
          else
            w="''${win[$n]}"
            wo="$(owner_of "$w")" so="$(owner_of "$f")"
            # Store owners (hm/nix/system) winning over macos/homebrew is the
            # sanctioned PATH order; only an inverted or foreign winner drifts.
            case "$wo" in hm | nix | system) continue ;; esac
            if [ "$wo" != "$so" ]; then
              wt="$(readlink -f "$w" 2>/dev/null || echo "$w")"
              st="$(readlink -f "$f" 2>/dev/null || echo "$f")"
              if [ "$wt" != "$st" ]; then
                shadows=$((shadows + 1))
                row shadow "command=$n\twinner=$wo:$w\tshadowed=$so:$f"
              fi
            fi
          fi
        done
      done

      # Seed case: MAGIC pins a store magic database; the serving binary must
      # be the store file, never /usr/bin/file 5.41 (v20-magic rejection).
      f_bin="$(command -v file || true)"
      f_owner="$(owner_of "''${f_bin:-/dev/null}")"
      if [ -n "''${MAGIC:-}" ] && [ "$f_owner" = macos ]; then
        mismatches=$((mismatches + 1))
        row file-magic "state=mismatch\tfile=$f_bin\tmagic=''${MAGIC}\tfix=install pkgs.file beside the MAGIC export"
      else
        row file-magic "state=ok\tfile=''${f_bin:-absent}\towner=$f_owner"
      fi

      # CLT health: native builds break silently when the CLT tree drifts.
      clt="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
      if [ -n "$clt" ] && [ -d "$clt" ]; then
        cltv="$(/usr/sbin/pkgutil --pkg-info=com.apple.pkg.CLTools_Executables 2>/dev/null | awk '/^version:/ {print $2}' || true)"
        row clt "state=ok\tpath=$clt\tversion=''${cltv:-unknown}"
      else
        mismatches=$((mismatches + 1))
        row clt "state=missing\tfix=xcode-select --install"
      fi

      # Brew posture: taps and pins are read-only telemetry rows.
      if [ -x "$brew_bin" ]; then
        row brew "taps=$("$brew_bin" tap 2>/dev/null | paste -sd, - || true)"
        row brew "pinned=$("$brew_bin" list --pinned 2>/dev/null | paste -sd, - || echo none)"
      else
        row brew "state=absent\tpath=$brew_bin"
      fi

      # ~/.local/bin inventory: owner class from the resolved target, decision
      # from the ruling table; unruled entries surface loudly.
      for f in "$HOME/.local/bin"/*; do
        [ -e "$f" ] || [ -L "$f" ] || continue
        n="''${f##*/}"
        if [ -L "$f" ]; then
          tgt="$(readlink -f "$f" 2>/dev/null || echo broken)"
          case "$tgt" in
            /nix/*) cls=hm ;;
            "$HOME/.local/share/uv"*) cls=uv-lane ;;
            "$HOME/.local/share/claude"*) cls=app-launcher ;;
            /Applications/*) cls=app ;;
            broken) cls=broken-link ;;
            *) cls=other-link ;;
          esac
        else
          cls=unmanaged
        fi
        decision="$(jq -r --arg n "$n" '.[$n] // "unadjudicated"' '${localBinDecisions}')"
        [ "$decision" != "unadjudicated" ] || unadjudicated=$((unadjudicated + 1))
        row local-bin "entry=$n\tclass=$cls\tdecision=$decision"
      done

      persist_receipt "$(printf 'ts=%s\tshadows=%s\tmismatches=%s\tunadjudicated=%s\tresult=%s' \
        "$ts" "$shadows" "$mismatches" "$unadjudicated" "$([ $((shadows + mismatches)) = 0 ] && echo ok || echo drift)")"
    '';
  };

  # Launchd triage vocabulary: label-prefix rows classifying every non-Apple
  # agent; unmatched labels report unclassified and demand a row.
  launchdTriage = pkgs.writeText "forge-launchd-triage.json" (builtins.toJSON (lib.mapAttrsToList
    (prefix: t: {
      inherit prefix;
      class = lib.head t;
      note = lib.last t;
    })
    {
      "com.parametric-forge." = ["forge" "Forge launchd grammar"];
      "org.nix-community.home." = ["hm" "HM module agents"];
      "com.github.domt4.homebrew-autoupdate" = ["by-design" "forge-reconciler-declared updater pair; single-owner collapse open"];
      "com.grammarly." = ["residue" "uninstalled GUI residue; gui-removal open class"];
      "com.adobe." = ["vendor" "Adobe CC estate; retain-or-prune trust row open"];
      "com.amazon.codewhisperer" = ["residue" "legacy launcher; gui-removal open class"];
      "mega.mac." = ["residue" "MEGA updater poller; gui-removal open class"];
      "com.lwouis.alt-tab-macos" = ["trust-row-open" "AltTab retain-or-prune adjudication open"];
      "com.logi" = ["vendor" "Logitech manager; recurring nonzero exits are vendor-owned"];
      "org.pqrs." = ["vendor" "Karabiner services"];
      "com.openssh." = ["system" "ssh-agent"];
      "com.1password." = ["vendor" "1Password agents"];
      "com.bardiasamiee.codex.update" = ["vendor" "Codex self-updater"];
      "com.microsoft." = ["vendor" "Microsoft update/agent surfaces"];
      "com.macpaw." = ["vendor" "CleanMyMac MAS agents"];
      "com.spotify." = ["vendor" "Spotify startup helper"];
      "com.google." = ["vendor" "Google updater/drivefs"];
    }));

  # Launchd census doctor: declared plists (HM/Forge grammar) reconciled with
  # the live launchctl table — loaded state, pid, last exit, triage class per
  # row. Read-only; the reconciliation IS the receipt.
  forgeLaunchdDoctor = mkTool {
    name = "forge-launchd-doctor";
    inputs = [pkgs.coreutils pkgs.gnugrep pkgs.gawk pkgs.jq];
    text = ''
      declared=0 loaded=0 not_loaded=0 unmanaged=0 nonzero=0
      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT

      # Tab-split keeps labels with spaces intact (launchctl is TSV).
      /bin/launchctl list 2>/dev/null | awk -F '\t' 'NR > 1 {print $3 "\t" $1 "\t" $2}' >"$work/observed"

      classify() {
        jq -r --arg l "$1" 'map(select(.prefix as $p | $l | startswith($p))) | first // {class: "unclassified", note: "no triage row"} | .class + "\t" + .note' '${launchdTriage}'
      }

      obs() { grep -m1 "^$1	" "$work/observed" || true; }

      # Declared lane: every plist in the user LaunchAgents dir.
      for plist in "$HOME/Library/LaunchAgents"/*.plist; do
        [ -e "$plist" ] || continue
        label="$(/usr/bin/plutil -extract Label raw "$plist" 2>/dev/null || true)"
        [ -n "$label" ] || continue
        declared=$((declared + 1))
        o="$(obs "$label")"
        IFS=$'\t' read -r _ opid ostatus <<<"$o" || true
        IFS=$'\t' read -r cls note < <(classify "$label")
        if [ -n "$o" ]; then
          loaded=$((loaded + 1))
          [ "''${ostatus:-0}" = 0 ] || [ "''${ostatus:-0}" = "-" ] || nonzero=$((nonzero + 1))
          printf 'ts=%s\tlabel=%s\towner=declared\tclass=%s\tloaded=1\tpid=%s\tlast_exit=%s\tnote=%s\n' \
            "$ts" "$label" "$cls" "''${opid:--}" "''${ostatus:--}" "$note"
        else
          not_loaded=$((not_loaded + 1))
          printf 'ts=%s\tlabel=%s\towner=declared\tclass=%s\tloaded=0\tpid=-\tlast_exit=-\tnote=%s\n' \
            "$ts" "$label" "$cls" "$note"
        fi
        printf '%s\n' "$label" >>"$work/declared"
      done

      # Observed lane: live labels with no declared plist. Apple system rows
      # and per-app transient rows stay out of the census.
      while IFS=$'\t' read -r label opid ostatus; do
        case "$label" in
          com.apple.* | application.* | *.anonymous.* | PID | "") continue ;;
        esac
        ! grep -qxF "$label" "$work/declared" 2>/dev/null || continue
        unmanaged=$((unmanaged + 1))
        [ "''${ostatus:-0}" = 0 ] || nonzero=$((nonzero + 1))
        IFS=$'\t' read -r cls note < <(classify "$label")
        printf 'ts=%s\tlabel=%s\towner=live-only\tclass=%s\tloaded=1\tpid=%s\tlast_exit=%s\tnote=%s\n' \
          "$ts" "$label" "$cls" "''${opid:--}" "''${ostatus:--}" "$note"
      done <"$work/observed"

      persist_receipt "$(printf 'ts=%s\tdeclared=%s\tloaded=%s\tnot_loaded=%s\tlive_only=%s\tnonzero_exit=%s\tresult=%s' \
        "$ts" "$declared" "$loaded" "$not_loaded" "$unmanaged" "$nonzero" \
        "$([ "$not_loaded" = 0 ] && echo ok || echo drift)")"
    '';
  };

  # Repeatable parity rail: the one-shot g2-t13 audit as a standing command.
  # Generation home-files vs live $HOME (store-linked, staged-equal, missing,
  # drifted), broken store links across managed roots, HM gc-root singleton.
  forgeParity = mkTool {
    name = "forge-parity";
    inputs = [pkgs.coreutils pkgs.diffutils pkgs.findutils pkgs.gnugrep pkgs.gawk];
    text = ''
      # HM rides nix-darwin: the generation resolves through the gc root, not
      # a nix profile.
      gen="$(readlink -f "$HOME/.local/state/home-manager/gcroots/current-home" 2>/dev/null || true)"
      hf="$gen/home-files"
      ok=0 staged=0 missing=0 drift=0 broken=0
      [ -d "$hf" ] || {
        printf 'forge-parity: no home-files at %s\n' "$hf" >&2
        exit 1
      }

      while IFS= read -r -d "" f; do
        rel="''${f#"$hf"/}"
        tgt="$HOME/$rel"
        if [ -L "$tgt" ] && [ "$(readlink -f "$tgt" 2>/dev/null || true)" = "$(readlink -f "$f")" ]; then
          ok=$((ok + 1))
        elif [ -f "$tgt" ] && cmp -s "$tgt" "$f"; then
          # Writable-staged class: physical by design, content byte-equal.
          staged=$((staged + 1))
        elif [ ! -e "$tgt" ]; then
          missing=$((missing + 1))
          printf 'ts=%s\tstate=missing\tpath=%s\n' "$ts" "$rel"
        else
          drift=$((drift + 1))
          printf 'ts=%s\tstate=drift\tpath=%s\n' "$ts" "$rel"
        fi
      done < <(find -H "$hf" -mindepth 1 \( -type f -o -type l \) -print0 2>/dev/null)

      # Broken store links across managed roots: a vanished generation target
      # is HM drift, distinct from the cleanup board's app-litter deadlinks.
      while IFS= read -r -d "" l; do
        tgt="$(readlink "$l" 2>/dev/null || true)"
        case "$tgt" in
          /nix/store/*)
            [ -e "$l" ] || {
              broken=$((broken + 1))
              printf 'ts=%s\tstate=broken-store-link\tpath=%s\ttarget=%s\n' "$ts" "''${l#"$HOME"/}" "$tgt"
            }
            ;;
        esac
      done < <(find "$HOME/.config" "$HOME/.local/share" "$HOME/.local/state" "$HOME/.local/bin" "$HOME/.ssh" "$HOME/Library/LaunchAgents" -maxdepth 8 \( -path "$HOME/.local/share/Trash" \) -prune -o -type l -print0 2>/dev/null)

      gcroots="$(find "$HOME/.local/state/home-manager/gcroots" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
      result=ok
      [ $((missing + drift + broken)) = 0 ] && [ "$gcroots" = 1 ] || result=drift
      persist_receipt "$(printf 'ts=%s\tgeneration=%s\tok=%s\tstaged=%s\tmissing=%s\tdrift=%s\tbroken_links=%s\tgcroots=%s\tresult=%s' \
        "$ts" "''${gen##*/}" "$ok" "$staged" "$missing" "$drift" "$broken" "$gcroots" "$result")"
      [ "$result" = ok ]
    '';
  };

  # Observation-only update-visibility board: one row per manifest family,
  # projected from existing receipts and local metadata. Mutation stays with
  # the per-family owners (forge-nix-drift, manifest engine verbs, brew).
  forgeUpdateBoard = mkTool {
    name = "forge-update-board";
    inputs = [pkgs.coreutils pkgs.gnugrep pkgs.gawk];
    text = ''
      brew_bin="''${FORGE_BREW:-/opt/homebrew/bin/brew}"
      logs="$HOME/Library/Logs"
      families=0

      # %b: payload fields carry embedded \t separators.
      row() {
        families=$((families + 1))
        printf 'ts=%s\tfamily=%s\towner=%s\t%b\n' "$ts" "$1" "$2" "$3"
      }
      tail_receipt() {
        if [ -f "$1" ]; then tail -1 "$1"; else echo "no-receipt"; fi
      }

      row flake-inputs forge-nix-drift "$(tail_receipt "$logs/forge-nix-drift.receipts.log")"
      row deploy forge-redeploy "$(tail_receipt "$logs/forge-redeploy.receipts.log")"
      row mcp-pins forge-mcp-outdated "$(grep -v '^$' "$logs/forge-mcp-outdated.log" 2>/dev/null | tail -1 || echo no-receipt)"
      if [ -x "$brew_bin" ]; then
        formulae="$(HOMEBREW_NO_AUTO_UPDATE=1 "$brew_bin" outdated --quiet 2>/dev/null | wc -l | tr -d ' ')"
        casks="$(HOMEBREW_NO_AUTO_UPDATE=1 "$brew_bin" outdated --cask --quiet 2>/dev/null | wc -l | tr -d ' ')"
        row homebrew operator-brew "outdated_formulae=$formulae\toutdated_casks=$casks"
      else
        row homebrew operator-brew "state=absent"
      fi
      if command -v uv >/dev/null 2>&1; then
        row uv-tools uv "installed_tools=$(uv tool list 2>/dev/null | grep -c '^[a-z]' || true)"
      fi
      row manifest overlays/manifest.nix "engine verbs update|advance|build own mutation; board observes"

      persist_receipt "$(printf 'ts=%s\tfamilies=%s\tresult=ok' "$ts" "$families")"
    '';
  };

  # Scheduled-agent fold: one Login Items identity (the automation bundle),
  # one log per agent, schedule and argv as the only per-row facts.
  mkAgent = name: schedule: argv: {
    enable = true;
    config =
      {
        Label = "com.parametric-forge.${name}";
        ProgramArguments = argv;
        ProcessType = "Background";
        StandardOutPath = "${logs}/${name}.log";
        StandardErrorPath = "${logs}/${name}.log";
        AssociatedBundleIdentifiers = [bundleId];
      }
      // schedule;
  };
in {
  home = {
    packages = [
      forgeRedeploy
      forgeNixMaintenance
      forgeCleanup
      forgeNixDrift
      forgeActivationSweep
      forgeAccept
      forgePathDoctor
      forgeLaunchdDoctor
      forgeParity
      forgeUpdateBoard
    ];

    # Shared identity bundle for the scheduled agents: Login Items &
    # Extensions shows one "Forge Nix Automation" row (one toggle governs
    # drift, maintenance, and the orphan sweep) instead of generic "/bin/sh"
    # entries.
    file."Applications/Forge Nix Automation.app/Contents/Info.plist".text = lib.generators.toPlist {escape = true;} {
      CFBundleIdentifier = bundleId;
      CFBundleName = "Forge Nix Automation";
      CFBundleDisplayName = "Forge Nix Automation";
      CFBundleVersion = "1";
      CFBundleShortVersionString = "1.0";
      CFBundlePackageType = "APPL";
      LSUIElement = true;
      LSBackgroundOnly = true;
    };

    activation.registerForgeNixAutomationApp = lib.hm.dag.entryAfter ["linkGeneration"] ''
      app="$HOME/Applications/Forge Nix Automation.app"
      lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
      if [ -d "$app" ] && [ -x "$lsregister" ]; then
        "$lsregister" -f "$app" || true
      fi
    '';
  };

  launchd.agents = {
    # Weekly off-peak cadence; the shared flock serializes against deploys.
    forge-nix-maintenance = mkAgent "forge-nix-maintenance" {
      StartCalendarInterval = [
        {
          Weekday = 6;
          Hour = 12;
          Minute = 0;
        }
      ];
    } ["${forgeNixMaintenance}/bin/forge-nix-maintenance" "--scheduled"];

    # Hourly orphan sweep: evidence-gated reaping of ppid-1 agent-lane litter;
    # kill classes are allowlisted rows, everything ambiguous stays receipt-only.
    forge-orphan-sweep = mkAgent "forge-orphan-sweep" {StartInterval = 3600;} ["${forgeCleanup}/bin/forge-cleanup" "sweep"];

    # Daily 10:00 currency cadence (operator ruling); calendar-only, no
    # RunAtLoad: login must never race a live campaign with a lock bump.
    forge-nix-drift = mkAgent "forge-nix-drift" {
      StartCalendarInterval = [
        {
          Hour = 10;
          Minute = 0;
        }
      ];
    } ["${forgeNixDrift}/bin/forge-nix-drift" "--scheduled"];
  };
}
