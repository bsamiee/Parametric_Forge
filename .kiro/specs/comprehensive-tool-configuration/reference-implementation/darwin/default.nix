# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/darwin/default.nix
# ----------------------------------------------------------------------------
# Darwin-specific configuration overrides for macOS-only tools and settings

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isDarwin {
  imports = [
    ./programs.nix
    ./environment.nix
    ./file-management.nix
    ./services.nix
  ];
}