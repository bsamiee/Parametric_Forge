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
  ];

  homebrew = {
    enable = mkDefault true;

    # --- Global Settings ----------------------------------------------------
    global = {
      autoUpdate = mkDefault true;
      brewfile = mkDefault false; # Disable Brewfile (managed via Nix)
    };

    # --- Activation Behavior ------------------------------------------------
    # Refresh Homebrew metadata during activation so cask API state does not drift.
    onActivation = {
      autoUpdate = mkDefault true;
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
