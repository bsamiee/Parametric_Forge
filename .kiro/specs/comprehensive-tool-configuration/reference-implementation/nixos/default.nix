# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/nixos/default.nix
# ----------------------------------------------------------------------------
# NixOS-specific configuration overrides for Linux-only tools and settings

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  imports = [
    ./programs.nix
    ./environment.nix
    ./file-management.nix
    ./services.nix
    ./desktop.nix
  ];
}