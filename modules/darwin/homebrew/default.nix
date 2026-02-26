# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/default.nix
# ----------------------------------------------------------------------------
# Homebrew configuration and aggregator
{lib, ...}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./taps.nix
    ./brews.nix
    ./casks.nix
    ./whalebrew.nix
  ];

  homebrew = {
    enable = mkDefault true;

    # --- Global Settings ----------------------------------------------------
    global = {
      autoUpdate = mkDefault false;
      brewfile = mkDefault false; # Disable Brewfile (managed via Nix)
      lockfiles = mkDefault false; # Prevent Nix store write attempts
    };

    # --- Activation Behavior ------------------------------------------------
    # Keep activation lightweight; avoid automatic updates/upgrades/cleanup.
    onActivation = {
      autoUpdate = mkDefault false;
      cleanup = mkDefault "none";
      upgrade = mkDefault false;
    };

    # --- Cask Configuration -------------------------------------------------
    caskArgs = mkDefault {
      appdir = "/Applications";
      require_sha = false; # Allow casks without SHA
      no_quarantine = true; # Skip Gatekeeper
      no_binaries = false; # Allow cask binaries in PATH
      fontdir = "~/Library/Fonts";
      colorpickerdir = "~/Library/ColorPickers";
      prefpanedir = "~/Library/PreferencePanes";
      qlplugindir = "~/Library/QuickLook";
    };
  };

}
