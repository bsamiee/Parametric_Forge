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
    # Do NOT auto-update Homebrew during activation: the metadata refresh shells out to git
    # (git-lfs smudge filters) which is absent from the root activation PATH, which aborts
    # `darwin-rebuild switch` mid-bundle. Refresh cask state with a manual `brew update`.
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
