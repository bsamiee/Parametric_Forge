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

let
  # --- Homebrew Variables ---------------------------------------------------
  homebrewVars = lib.optionalAttrs context.isDarwin {
    HOMEBREW_NO_ANALYTICS = "1"; # Privacy: disable telemetry and analytics
    HOMEBREW_NO_INSTALL_CLEANUP = "0"; # Allow cleanup after individual installs
    HOMEBREW_NO_EMOJI = "1"; # Cleaner CLI output
    # HOMEBREW_VERBOSE = "1"; # Disabled for performance - enable manually if debugging needed
    HOMEBREW_NO_ENV_HINTS = "1"; # Suppress environment setup hints
    HOMEBREW_CLEANUP_MAX_AGE_DAYS = "3"; # Aggressive cache cleanup
  };
in
{
  environment = {
    # --- System Variables ---------------------------------------------------
    variables = {
      NIX_REMOTE = "daemon";
      NIXPKGS_ALLOW_UNFREE = "1";
      CACHIX_CACHE = "bsamiee";
      EDITOR = "nvim";
      VISUAL = "nvim";
    }
    // homebrewVars;
    # --- XDG Profile Paths --------------------------------------------------
    profiles = lib.mkBefore [
      "${context.userHome}/.local/state/nix/profile"
      "${context.userHome}/.local/share/nix-defexpr/channels"
    ];
  };
}
