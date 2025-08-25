# Title         : lib/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/default.nix
# ----------------------------------------------------------------------------
# Aggregates and exports all library functions for central access.

{ nixpkgs }:

let
  inherit (nixpkgs) lib;

  # --- Import Library Modules -----------------------------------------------
  detection = import ./detection.nix { inherit lib; };
  configDefaults = import ./config-defaults.nix;
  gitStatus = import ./git-status.nix { inherit lib; };
in
{
  # --- Detection Functions --------------------------------------------------
  inherit (detection)
    isDarwin
    isLinux
    isAarch64
    isX86_64
    getSystemArch
    getSystemPlatform
    detectContext
    isContainer
    isVM
    ;

  # --- Font Utilities -------------------------------------------------------
  fonts = import ./font-patcher.nix { inherit nixpkgs; };

  # --- Build and Deployment -------------------------------------------------
  build = import ./build.nix { inherit nixpkgs; };

  # --- Launchd Utilities (Darwin) -------------------------------------------
  launchd = import ./launchd.nix { inherit lib; };

  # --- Exclusion Filters ----------------------------------------------------
  exclusionFilters = import ./exclusion-filters.nix { };

  # --- 1Password Utilities --------------------------------------------------
  secrets = import ./1password-helpers.nix { inherit lib; };

  # --- Development Shell Helpers --------------------------------------------
  devshell = import ./devshell-helpers.nix { inherit lib; };

  # --- Configuration Defaults -----------------------------------------------
  inherit configDefaults;

  # --- Git Status Utilities -------------------------------------------------
  inherit (gitStatus) getRepoStatus statusCommand statusChars;

  # --- Re-export Nixpkgs Lib Functions --------------------------------------
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    mkDefault
    mkForce
    ;
}
