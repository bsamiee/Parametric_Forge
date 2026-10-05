# Title         : redeploy.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/redeploy.nix
# ----------------------------------------------------------------------------
# redeploy, the only activation path: flake check, per-host toplevel build, closure diff, then the exact built path is registered and
# activated. Darwin builds and switches locally; NixOS check is eval-only (no Linux builder assumed), build proves a closure, switch activates
# locally on a NixOS host or remotely through nixos-rebuild-ng --target-host.
{
  config,
  lib,
  pkgs,
  ...
}: let
  redeploy = pkgs.writeShellApplication {
    name = "redeploy";
    runtimeInputs = [pkgs.coreutils pkgs.git pkgs.nh pkgs.nix-output-monitor pkgs.dix pkgs.cachix pkgs.nixos-rebuild-ng];
    text = ''
      # The Determinate profile leads PATH so every nix/nix-env call (nh's included) resolves the daemon-matched client.
      export PATH="/nix/var/nix/profiles/default/bin:$PATH"
      mode="check"
      # Default --os keys on the running kernel: a NixOS host must never ride the darwin rail by default; --os stays the explicit override.
      os="$(case "$(uname -s)" in Linux) echo nixos ;; *) echo darwin ;; esac)"
      host=""
      target_host=""
      usage() {
        printf 'Usage: redeploy [--os darwin|nixos] [--host NAME] [--target-host SSH]\n'
        printf '                [--check-only|--build|--switch]\n'
      }
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --check-only) mode="check" ;;
          --build) mode="build" ;;
          --switch) mode="switch" ;;
          --os)
            os="''${2:?redeploy: --os requires darwin|nixos}"
            shift
            ;;
          --host)
            host="''${2:?redeploy: --host requires a flake host name}"
            shift
            ;;
          --target-host)
            target_host="''${2:?redeploy: --target-host requires an ssh destination}"
            shift
            ;;
          --help | -h)
            usage
            exit 0
            ;;
          *)
            printf 'redeploy: unknown argument: %s\n' "$1" >&2
            exit 2
            ;;
        esac
        shift
      done
      case "$os" in
        darwin | nixos) ;;
        *)
          printf 'redeploy: --os must be darwin or nixos, got: %s\n' "$os" >&2
          exit 2
          ;;
      esac
      if [ -z "$host" ]; then
        if [ "$os" = "darwin" ]; then host="macbook"; else host="vps"; fi
      fi

      flake_root="${config.estate.lsp.flakeRoot}"
      cache="${config.home.sessionVariables.CACHIX_CACHE}"
      secrets_file="${config.estate.secrets.sessionCache}"
      custom_conf="/etc/nix/nix.custom.conf"
      profile="/nix/var/nix/profiles/system"
      nix_env="/nix/var/nix/profiles/default/bin/nix-env"

      tmpdir="$(mktemp -d "''${TMPDIR:-/tmp}/redeploy.XXXXXX")"
      trap 'rm -rf "$tmpdir"' EXIT
      out_link="$tmpdir/system"

      # Ambient CACHIX_AUTH_TOKEN wins, the op session cache resolves the machine rail, absence degrades to a skipped push. A present-but-bad
      # token never fails an already-built/switched deploy.
      if [ -z "''${CACHIX_AUTH_TOKEN:-}" ] && [ -f "$secrets_file" ]; then
        # shellcheck source=/dev/null
        . "$secrets_file" || true
      fi
      # Every build-capable phase runs under `cachix watch-exec`: its post-build hook pushes each path the moment the daemon finishes building it,
      # so a check or build that fails later — or a switch that never lands — still banks every compiled path. No token: the bare command runs.
      banked() {
        if [ -n "''${CACHIX_AUTH_TOKEN:-}" ]; then
          cachix watch-exec "$cache" -- "$@"
        else
          "$@"
        fi
      }
      push_cache() {
        if [ -z "''${CACHIX_AUTH_TOKEN:-}" ]; then
          printf 'redeploy: cache push skipped: CACHIX_AUTH_TOKEN unset\n' >&2
          return 0
        fi
        cachix push "$cache" "$1" || printf 'redeploy: WARNING cache push failed (token/network); deploy unaffected\n' >&2
      }

      # Post-activation contract: live-system equality, then the daemon kickstart (daemon-side settings go live only after restart).
      assert_live() {
        live_system="$(readlink /run/current-system)"
        if [ "$live_system" != "$1" ]; then
          printf 'redeploy: FATAL live system %s != built %s\n' "$live_system" "$1" >&2
          exit 1
        fi
        sudo -n /bin/launchctl kickstart -k system/systems.determinate.nix-daemon
      }

      # Activation's /etc collision guard exits 2 on an installer-written real file; one adoption owner serves the switch activation.
      adopt_custom_conf() {
        { [ -f "$custom_conf" ] && [ ! -L "$custom_conf" ]; } || return 0
        sudo -n /bin/mv "$custom_conf" "$custom_conf.before-determinate-module"
      }

      [ -f "$flake_root/flake.nix" ] || {
        printf 'redeploy: missing flake root: %s\n' "$flake_root" >&2
        exit 1
      }
      cd "$flake_root"

      printf 'redeploy: nix=%s\n' "$(command -v nix)"
      banked nix flake check --print-build-logs

      if [ "$os" = "darwin" ]; then
        attr="darwinConfigurations.$host.system"
      else
        attr="nixosConfigurations.$host.config.system.build.toplevel"
      fi

      # NixOS dispatch: eval-only check (drv identity), real-closure build, local nh switch on a NixOS host, remote target-built switch otherwise.
      if [ "$os" = "nixos" ]; then
        case "$mode" in
          check)
            system_path="$(nix eval --raw "$flake_root#$attr.drvPath")"
            printf 'redeploy: check-only ok (eval) drv=%s\n' "$system_path"
            ;;
          build)
            system_path="$(banked nix build --no-link --print-out-paths "$flake_root#$attr")"
            push_cache "$system_path"
            printf 'redeploy: build ok system=%s\n' "$system_path"
            ;;
          switch)
            if [ "$(uname -s)" = "Linux" ] && [ -z "$target_host" ]; then
              system_path="$(banked nix build --no-link --print-out-paths "$flake_root#$attr")"
              nh os switch --hostname "$host" "$flake_root"
            else
              [ -n "$target_host" ] || {
                printf 'redeploy: --switch --os nixos from Darwin needs --target-host\n' >&2
                exit 2
              }
              system_path="$(nix eval --raw "$flake_root#$attr.drvPath")"
              # Target-built activation: no local Linux builder is assumed; nixos-rebuild-ng evaluates locally and builds on the target. The -ng
              # package ships its binary as plain nixos-rebuild; --no-reexec stops the cross-platform local self-rebuild.
              sudo_flag=(--sudo)
              case "$target_host" in root@*) sudo_flag=() ;; esac
              nixos-rebuild switch --flake "$flake_root#$host" --no-reexec \
                --target-host "$target_host" --build-host "$target_host" \
                "''${sudo_flag[@]}"
            fi
            push_cache "$system_path"
            printf 'redeploy: switch ok os=nixos host=%s target=%s system=%s\n' \
              "$host" "''${target_host:-local}" "$system_path"
            ;;
        esac
        exit 0
      fi

      # Every Darwin mode builds the toplevel through nh and reviews the diff.
      banked nh darwin build --hostname "$host" --out-link "$out_link" --diff never "$flake_root"
      system_path="$(readlink -f "$out_link")"
      [ ! -e /run/current-system ] || dix /run/current-system "$system_path"

      case "$mode" in
        check)
          printf 'redeploy: check-only ok system=%s\n' "$system_path"
          ;;
        build)
          push_cache "$system_path"
          printf 'redeploy: build ok system=%s\n' "$system_path"
          ;;
        switch)
          adopt_custom_conf
          # Exact-closure activation: the reviewed store path is registered and activated directly, never re-evaluated. -H seats root's own HOME:
          # nix under a preserved user HOME warns on the ownership mismatch and falls back to it anyway.
          sudo -n -H "$nix_env" -p "$profile" --set "$system_path"
          sudo -n -H "$system_path/sw/bin/darwin-rebuild" activate
          # Push precedes the kickstart so it never races the daemon restart.
          push_cache "$system_path"
          assert_live "$system_path"
          printf 'redeploy: switch ok system=%s\n' "$system_path"
          ;;
      esac
    '';
  };
in {
  home.packages = [redeploy];

  # Homebrew's user environment file (bin/brew reads $XDG_CONFIG_HOME/homebrew/brew.env before every command): the one owner of the standing
  # HOMEBREW_* rows for the interactive session and activation's `brew bundle`, which both carry XDG_CONFIG_HOME. Values are literal per the
  # manpage (no shell expansion). An `auto_updates` cask stays with its own updater: `brew upgrade` otherwise replaces the app whenever its bundle
  # trails the tap and quits it first, and the 1password cask's quit stops the SSH agent and commit signer with nothing to relaunch them.
  xdg.configFile."homebrew/brew.env" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    text = ''
      HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1
      HOMEBREW_NO_ANALYTICS=1
      HOMEBREW_NO_ENV_HINTS=1
      HOMEBREW_NO_EMOJI=1
      HOMEBREW_CLEANUP_MAX_AGE_DAYS=3
    '';
  };
}
