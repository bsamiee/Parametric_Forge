# Title         : forge-redeploy.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/forge-redeploy.nix
# ----------------------------------------------------------------------------
# forge-redeploy, the only activation path: flake check, per-host toplevel build, closure diff, then the exact built path is registered and
# activated. Darwin builds and switches locally; NixOS check is eval-only (no Linux builder assumed), build proves a closure, switch activates
# locally on a NixOS host or remotely through nixos-rebuild-ng --target-host.
{
  config,
  lib,
  pkgs,
  ...
}: let
  forgeRedeploy = pkgs.writeShellApplication {
    name = "forge-redeploy";
    runtimeInputs = [pkgs.coreutils pkgs.git pkgs.nh pkgs.nix-output-monitor pkgs.dix pkgs.cachix pkgs.nixos-rebuild-ng];
    text = ''
      # The Determinate profile leads PATH so every nix/nix-env call (nh's included) resolves the daemon-matched client.
      export PATH="/nix/var/nix/profiles/default/bin:$PATH"
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

      forge_root="''${FORGE_ROOT:-${config.forge.lsp.flakeRoot}}"
      cache="${config.home.sessionVariables.CACHIX_CACHE}"
      secrets_file="${config.forge.secrets.sessionCache}"
      custom_conf="/etc/nix/nix.custom.conf"
      profile="/nix/var/nix/profiles/system"
      nix_env="/nix/var/nix/profiles/default/bin/nix-env"

      tmpdir="$(mktemp -d "''${TMPDIR:-/tmp}/forge-redeploy.XXXXXX")"
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
          printf 'forge-redeploy: cache push skipped: CACHIX_AUTH_TOKEN unset\n' >&2
          return 0
        fi
        cachix push "$cache" "$1" || printf 'forge-redeploy: WARNING cache push failed (token/network); deploy unaffected\n' >&2
      }

      # Post-activation contract: live-system equality, then the daemon kickstart (daemon-side settings go live only after restart).
      assert_live() {
        live_system="$(readlink /run/current-system)"
        if [ "$live_system" != "$1" ]; then
          printf 'forge-redeploy: FATAL live system %s != built %s\n' "$live_system" "$1" >&2
          exit 1
        fi
        sudo -n /bin/launchctl kickstart -k system/systems.determinate.nix-daemon \
          || printf 'forge-redeploy: WARNING daemon kickstart failed; daemon-side settings stay dormant until restart\n' >&2
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
            system_path="$(nix eval --raw "$forge_root#$attr.drvPath")"
            printf 'forge-redeploy: check-only ok (eval) drv=%s\n' "$system_path"
            ;;
          build)
            system_path="$(banked nix build --no-link --print-out-paths "$forge_root#$attr")"
            push_cache "$system_path"
            printf 'forge-redeploy: build ok system=%s\n' "$system_path"
            ;;
          switch)
            if [ "$(uname -s)" = "Linux" ] && [ -z "$target_host" ]; then
              system_path="$(banked nix build --no-link --print-out-paths "$forge_root#$attr")"
              nh os switch --hostname "$host" "$forge_root"
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
              nixos-rebuild switch --flake "$forge_root#$host" --no-reexec \
                --target-host "$target_host" --build-host "$target_host" \
                "''${sudo_flag[@]}"
            fi
            push_cache "$system_path"
            printf 'forge-redeploy: switch ok os=nixos host=%s target=%s system=%s\n' \
              "$host" "''${target_host:-local}" "$system_path"
            ;;
        esac
        exit 0
      fi

      # Every Darwin mode builds the toplevel through nh and reviews the diff.
      banked nh darwin build --hostname "$host" --out-link "$out_link" --diff never "$forge_root"
      system_path="$(readlink -f "$out_link")"
      [ ! -e /run/current-system ] || dix /run/current-system "$system_path"

      case "$mode" in
        check)
          printf 'forge-redeploy: check-only ok system=%s\n' "$system_path"
          ;;
        build)
          push_cache "$system_path"
          printf 'forge-redeploy: build ok system=%s\n' "$system_path"
          ;;
        switch)
          adopt_custom_conf
          # Exact-closure activation: the reviewed store path is registered and activated directly, never re-evaluated. -H seats root's own HOME:
          # nix under a preserved user HOME warns on the ownership mismatch and falls back to it anyway.
          sudo -n -H "$nix_env" -p "$profile" --set "$system_path" || {
            printf 'forge-redeploy: profile registration denied; sudoers rows land on first switch.\n' >&2
            printf 'forge-redeploy: run once: sudo %s -p %s --set %s && sudo %s/sw/bin/darwin-rebuild activate\n' \
              "$nix_env" "$profile" "$system_path" "$system_path" >&2
            exit 1
          }
          sudo -n -H "$system_path/sw/bin/darwin-rebuild" activate || {
            printf 'forge-redeploy: FATAL activation failed; if sudo denied, run once: sudo %s/sw/bin/darwin-rebuild activate\n' "$system_path" >&2
            exit 1
          }
          # Post-activation steps degrade to warnings: the deploy already landed. Push precedes the kickstart so it never races the daemon restart.
          push_cache "$system_path"
          assert_live "$system_path"
          printf 'forge-redeploy: switch ok system=%s\n' "$system_path"
          ;;
      esac
    '';
  };
in {
  home.packages = [forgeRedeploy];

  # Homebrew's user environment file (bin/brew reads $XDG_CONFIG_HOME/homebrew/brew.env before every command): the one owner of the standing
  # HOMEBREW_* rows for the interactive session and activation's `brew bundle`, which both carry XDG_CONFIG_HOME. Values are literal per the
  # manpage (no shell expansion).
  xdg.configFile."homebrew/brew.env" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    text = ''
      HOMEBREW_NO_ANALYTICS=1
      HOMEBREW_NO_ENV_HINTS=1
      HOMEBREW_NO_EMOJI=1
      HOMEBREW_CLEANUP_MAX_AGE_DAYS=3
    '';
  };
}
