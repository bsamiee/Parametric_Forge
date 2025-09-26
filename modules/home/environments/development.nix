# Title         : development.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/development.nix
# ----------------------------------------------------------------------------
# Development tools and version control

{ config, ... }:

{
  home.sessionVariables = {
    # --- Package Managers ----------------------------------------------------
    # Homebrew
    HOMEBREW_CLEANUP_MAX_AGE_DAYS = "3";
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_NO_EMOJI = "1";
    HOMEBREW_NO_ENV_HINTS = "1";

    # Nix
    NIX_INDEX_DATABASE = "${config.xdg.cacheHome}/nix-index";
    CACHIX_CACHE = "bsamiee";
    NIX_REMOTE = "daemon";

    # --- Build & Pre-commit --------------------------------------------------
    PRE_COMMIT_HOME = "${config.xdg.dataHome}/pre-commit";
    # CMAKE_BUILD_PARALLEL_LEVEL = "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";
    # MAKEFLAGS = "-j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";

    # --- Task Runner ---------------------------------------------------------
    # JUST_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S";
    # JUST_CHOOSER = "fzf";
    # JUST_TIMESTAMP = "1";
    # JUST_UNSTABLE = "1";

    # --- File Operations -----------------------------------------------------
    # RCLONE_CONFIG = "${config.xdg.configHome}/rclone/rclone.conf";
    # RESTIC_CACHE_DIR = "${config.xdg.cacheHome}/restic";
    # PARALLEL = "-j+0 --bar --eta";
    # RSYNC_RSH = "ssh";

    # --- Development Utilities -----------------------------------------------
    XH_CONFIG_DIR = "${config.xdg.configHome}/xh";
  };
}
