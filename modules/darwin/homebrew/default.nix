# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/default.nix
# ----------------------------------------------------------------------------
# Homebrew configuration and aggregator
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep mkDefault;
  activationPath = concatStringsSep ":" [
    "/etc/profiles/per-user/${config.system.primaryUser}/bin"
    "/run/current-system/sw/bin"
    "${config.homebrew.prefix}/bin"
    "${pkgs.mas}/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
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
      autoUpdate = mkDefault true; # Manual brew ops refresh tap metadata natively
      brewfile = mkDefault false; # Disable Brewfile (managed via Nix)
    };

    # --- Activation Behavior ------------------------------------------------
    # Keep Homebrew flexible; explicit cleanup/drift checks stay operator-owned.
    # Version upgrades are owned by the domt4/autoupdate launchd agent, not activation.
    onActivation = {
      autoUpdate = mkDefault true;
      cleanup = mkDefault "none";
      upgrade = mkDefault false;
      extraEnv = {
        PATH = mkDefault activationPath;
      };
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
