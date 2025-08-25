# Title         : 00.system/environment.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/environment.nix
# ----------------------------------------------------------------------------
# System-level environment variables for daemons and services.

{
  lib,
  context,
  ...
}:

{
  environment = {
    # --- System Variables ---------------------------------------------------
    variables = {
      NIX_REMOTE = "daemon";
      NIXPKGS_ALLOW_UNFREE = "1";
      CACHIX_CACHE = "bsamiee"; # Default cache for Cachix operations
      EDITOR = "nvim";
      VISUAL = "nvim"; # System daemons can't use GUI editors
    }
    // lib.optionalAttrs context.isDarwin {
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_AUTO_UPDATE = "1";
      HOMEBREW_NO_INSTALL_CLEANUP = "0";
      HOMEBREW_NO_ENV_HINTS = "1"; # Disable environment hints
      HOMEBREW_CLEANUP_MAX_AGE_DAYS = "30"; # Auto-cleanup old versions
    };
    # --- XDG Profile Paths --------------------------------------------------
    profiles = lib.mkBefore [
      "${context.userHome}/.local/state/nix/profile"
      "${context.userHome}/.local/share/nix-defexpr/channels"
    ];
  };
}
