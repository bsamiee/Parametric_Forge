# Title         : 00.system/darwin/homebrew.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/homebrew.nix
# ----------------------------------------------------------------------------
# Homebrew and Mac App Store integration via nix-homebrew.

{ lib, context, ... }:

let
  inherit (lib) mkDefault;
in
{
  # --- Homebrew Integration -------------------------------------------------
  homebrew = {
    enable = mkDefault true;

    # --- Global Settings ----------------------------------------------------
    global = {
      autoUpdate = mkDefault false;
      brewfile = mkDefault true; # Enable Brewfile management
      lockfiles = mkDefault true; # Lock files for reproducible state
    };
    # --- Activation Behavior ------------------------------------------------
    onActivation = {
      autoUpdate = mkDefault false;
      cleanup = mkDefault "zap"; # Remove all unmanaged packages
      upgrade = mkDefault false;
      extraFlags = mkDefault [ ]; # Add "--verbose" for debugging
    };
    # --- Essential Taps -----------------------------------------------------
    taps = [
      "homebrew/services" # Service management
      # Add more taps as needed
    ];
    # --- GUI Applications (Casks) -------------------------------------------
    casks = [
      "1password" # Password manager with macOS integration
      "wezterm@nightly" # Terminal emulator (nightly build)
      "dotnet-sdk" # .NET SDK (large, GUI tools)
      "cleanshot" # Advanced screenshot and screen recording tool
    ];
    # --- CLI Tools (Brews) --------------------------------------------------
    brews = [
      "terminal-notifier" # macOS notification system integration
      "mono" # .NET runtime (dependency for some tools)
      "codex" # AI coding assistant (ChatGPT CLI)
    ];
    # --- Mac App Store Applications -----------------------------------------
    masApps = { };
    # --- Whalebrew (Docker-based tools) -------------------------------------
    # whalebrews = [ ];

    # --- Cask Configuration -------------------------------------------------
    caskArgs = mkDefault {
      appdir = "/Applications";
      require_sha = true; # Security: verify checksums
      no_quarantine = true; # Performance: skip Gatekeeper (safe with SHA verification)
    };
  };
  # --- Nix-Homebrew Bridge Integration --------------------------------------
  nix-homebrew = {
    enable = mkDefault true;
    enableRosetta = mkDefault context.isAarch64; # Enable Rosetta for Apple Silicon Macs (x86_64 compatibility)
    inherit (context) user;
    autoMigrate = mkDefault true;
  };
}
