# Title         : config.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/config.nix
# ----------------------------------------------------------------------------
# Zsh .zshenv env floor: PATH-neutral nix/Homebrew metadata and the never-clobber session-variable fallback.
{
  config,
  forgeToolchainEnvFor,
  ...
}: let
  toolchainEnv = forgeToolchainEnvFor {
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
    xdgConfigHome = config.xdg.configHome;
  };
in {
  programs.zsh = {
    # Runs in .zshenv for ALL shells (login, interactive, scripts, zellij panes). PATH has ONE owner: home.sessionPath via hm-session-vars; no writers here.
    envExtra = ''
      setopt no_equals # bare =-leading words (===, =foo) pass through as literals in every shell; =(...) process substitution is unaffected
      setopt no_nomatch # unmatched globs pass through literally so the tool reports honestly, matching sh/bash expansion semantics

      if [[ -o interactive && -z "''${TERM:-}" ]]; then
        export TERM="dumb"
      fi

      # Nix daemon profile without PATH authority: non-login panes get NIX_* certs/profiles; PATH restore keeps home.sessionPath the single owner
      # and the sourced-guard makes the /etc/zshrc login pass a no-op.
      if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        _forge_prenix_path="$PATH"
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        export PATH="$_forge_prenix_path"
        unset _forge_prenix_path
      fi

      # Homebrew man/info membership growth (prefix constants own their env vocabulary rows); guards block nested growth per shell.
      if [[ -x "/opt/homebrew/bin/brew" ]]; then
        [[ ":''${MANPATH:-}:" != *":/opt/homebrew/share/man:"* ]] && \
          export MANPATH="/opt/homebrew/share/man''${MANPATH+:$MANPATH}:"
        [[ ":''${INFOPATH:-}:" != *":/opt/homebrew/share/info:"* ]] && \
          export INFOPATH="/opt/homebrew/share/info:''${INFOPATH:-}"
      fi

      ${toolchainEnv.shellExports toolchainEnv.scientificSessionEnv}
      ${toolchainEnv.resilientFloorExports}
    '';
  };
}
