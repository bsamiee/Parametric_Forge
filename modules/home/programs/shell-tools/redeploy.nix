# Title         : redeploy.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/redeploy.nix
# ----------------------------------------------------------------------------
# redeploy, the only activation path: `nix flake check`, the host toplevel built to a stable out-link, `nvd diff` against the live system,
# activation of the linked path, then a Cachix push. The out-link is a GC root, so a failed build resumes from the store, and `--switch`
# activates the toplevel a previous `--build` linked instead of building it again; activation consumes the link.
{
  config,
  host,
  osConfig,
  pkgs,
  ...
}: let
  redeploy = pkgs.writeShellApplication {
    name = "redeploy";
    runtimeInputs = [pkgs.cachix pkgs.coreutils pkgs.nvd];
    text = ''
      mode="build"
      host="${host.name}"
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --build) mode="build" ;;
          --switch) mode="switch" ;;
          --host)
            host="''${2:?redeploy: --host requires a flake host name}"
            shift
            ;;
          --help | -h)
            printf 'Usage: redeploy [--host NAME] [--build|--switch]\n'
            exit 0
            ;;
          *)
            printf 'redeploy: unknown argument: %s\n' "$1" >&2
            exit 2
            ;;
        esac
        shift
      done

      link="${config.xdg.stateHome}/redeploy/$host"
      if [ "$mode" = build ] || [ ! -e "$link" ]; then
        nix flake check "${host.flakeRoot}"
        mkdir -p "''${link%/*}"
        nix build "${host.flakeRoot}#darwinConfigurations.$host.config.system.build.toplevel" --keep-going --out-link "$link"
        nvd diff /run/current-system "$link"
      fi
      system="$(readlink "$link")"

      if [ "$mode" = switch ]; then
        sudo -H /nix/var/nix/profiles/default/bin/nix-env -p /nix/var/nix/profiles/system --set "$system"
        sudo -H "$system/sw/bin/darwin-rebuild" activate
        rm "$link"
      fi

      # An ambient CACHIX_AUTH_TOKEN wins over the op session cache; with neither, the push is skipped.
      if [ -z "''${CACHIX_AUTH_TOKEN:-}" ] && [ -f "${config.forge.secrets.sessionCache}" ]; then
        # shellcheck source=/dev/null
        . "${config.forge.secrets.sessionCache}"
      fi
      [ -z "''${CACHIX_AUTH_TOKEN:-}" ] || cachix push "${osConfig.cachix.cache}" "$system"
    '';
  };
in {
  home.packages = [redeploy];

  # Homebrew's user environment file (bin/brew reads $XDG_CONFIG_HOME/homebrew/brew.env before every command): the one owner of the standing
  # HOMEBREW_* rows for the interactive session and activation's `brew bundle`, which both carry XDG_CONFIG_HOME. Values are literal per the
  # manpage (no shell expansion). An `auto_updates` cask stays with its own updater: `brew upgrade` otherwise replaces the app whenever its bundle
  # trails the tap and quits it first, and the 1password cask's quit stops the SSH agent and commit signer with nothing to relaunch them.
  xdg.configFile."homebrew/brew.env".text = ''
    HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1
    HOMEBREW_NO_ANALYTICS=1
    HOMEBREW_NO_ENV_HINTS=1
    HOMEBREW_NO_EMOJI=1
    HOMEBREW_CLEANUP_MAX_AGE_DAYS=3
  '';
}
