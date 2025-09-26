# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/default.nix
# ----------------------------------------------------------------------------
# Homebrew configuration and aggregator

{ config, lib, pkgs, ... }:

let
  inherit (lib) mkDefault;
  inherit (pkgs.stdenv) isAarch64;
in
{
  imports = [
    ./taps.nix
    ./brews.nix
    ./casks.nix
    ./whalebrew.nix
  ];

  homebrew = {
    enable = mkDefault true;

    # --- Global settings ----------------------------------------------------
    global = {
      autoUpdate = mkDefault true;
      brewfile = mkDefault false;   # Disable Brewfile (managed via Nix)
      lockfiles = mkDefault false;  # Prevent Nix store write attempts
    };

    # --- Activation behavior ------------------------------------------------
    onActivation = {
      autoUpdate = mkDefault true;
      cleanup = mkDefault "uninstall";
      upgrade = mkDefault true;
    };

    # --- Cask configuration -------------------------------------------------
    caskArgs = mkDefault {
      appdir = "/Applications";
      require_sha = false;              # Allow casks without SHA
      no_quarantine = true;             # Skip Gatekeeper
      no_binaries = false;              # Allow cask binaries in PATH
      fontdir = "~/Library/Fonts";
      colorpickerdir = "~/Library/ColorPickers";
      prefpanedir = "~/Library/PreferencePanes";
      qlplugindir = "~/Library/QuickLook";
    };
  };

  # --- Nix-Homebrew bridge integration --------------------------------------
  nix-homebrew = {
    enable = mkDefault true;
    enableRosetta = mkDefault isAarch64;  # Enable Rosetta for Apple Silicon
    user = config.system.primaryUser;     # Dynamic from system configuration
    autoMigrate = mkDefault true;
  };
}
