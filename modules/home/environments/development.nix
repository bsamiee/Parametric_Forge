# Title         : development.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/development.nix
# ----------------------------------------------------------------------------
# Development tools and version control
{config, ...}: {
  home.sessionVariables = {
    # --- Package Managers ---------------------------------------------------
    # Homebrew
    HOMEBREW_CLEANUP_MAX_AGE_DAYS = "3";
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_NO_EMOJI = "1";
    HOMEBREW_NO_ENV_HINTS = "1";
    # Nix
    CACHIX_CACHE = "bsamiee";
    NIX_REMOTE = "daemon";
    NIX_INDEX_DATABASE = "${config.xdg.cacheHome}/nix-index";

    # --- Git & Version Control ----------------------------------------------
    GITLEAKS_CONFIG = "${config.xdg.configHome}/gitleaks/gitleaks.toml";
    GH_CONFIG_DIR = "${config.xdg.configHome}/gh";
    GH_PAGER = "delta"; # Delta specifically for git/gh diffs
    GIT_PAGER = "delta"; # Ensure git uses delta

    # --- Build & Pre-commit -------------------------------------------------
    PRE_COMMIT_HOME = "${config.xdg.dataHome}/pre-commit";
  };
}
