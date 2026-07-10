# Title         : development.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/development.nix
# ----------------------------------------------------------------------------
# Development tools and version control

{
  config,
  lib,
  pkgs,
  ...
}: {
  home.sessionVariables =
    # Homebrew exists on Darwin only; its rows are dead weight on NixOS.
    lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      HOMEBREW_CASK_OPTS = "--no-quarantine"; # Brew 6 dropped the install flag; env is the only carrier
      HOMEBREW_CLEANUP_MAX_AGE_DAYS = "3";
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_EMOJI = "1";
      HOMEBREW_NO_ENV_HINTS = "1";
    }
    // {
      # --- [NIX]
      CACHIX_CACHE = "bsamiee";
      NIX_REMOTE = "daemon";

      # --- [GIT_VERSION_CONTROL]
      GITLEAKS_CONFIG = "${config.xdg.configHome}/gitleaks/gitleaks.toml";
      GH_CONFIG_DIR = "${config.xdg.configHome}/gh";
      # Difftastic brightness follows the estate surface luminance, not a mode literal
      DFT_BACKGROUND = let
        surface = config.forge.theme.palette.background;
      in
        if surface.r + surface.g + surface.b < 384
        then "dark"
        else "light";

      # --- [BUILD_PRE_COMMIT]
      PRE_COMMIT_HOME = "${config.xdg.dataHome}/pre-commit";

      # --- [AI_CLAUDE]
      CLAUDE_CODE_DISABLE_AUTO_MEMORY = "0"; # Force auto-memory on (double-negative: DISABLE=0)
    };
}
