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
    CACHIX_CACHE = "bsamiee";
    NIX_REMOTE = "daemon";
    NIX_INDEX_DATABASE = "${config.xdg.cacheHome}/nix-index";

    # --- File Operations -----------------------------------------------------
    RCLONE_CONFIG = "${config.xdg.configHome}/rclone/rclone.conf";
    RCLONE_TRANSFERS = "4";             # Balanced concurrent transfers
    RCLONE_CHECKERS = "8";              # Parallel checkers for syncing
    RSYNC_RSH = "ssh";                  # Explicit SSH transport for rsync

    # --- Task Runner ---------------------------------------------------------
    # JUST_TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S";
    # JUST_CHOOSER = "fzf";
    # JUST_TIMESTAMP = "1";
    # JUST_UNSTABLE = "1";

    # --- Build & Pre-commit --------------------------------------------------
    PRE_COMMIT_HOME = "${config.xdg.dataHome}/pre-commit";
    # CMAKE_BUILD_PARALLEL_LEVEL = "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";
    # MAKEFLAGS = "-j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)";
  };
}
