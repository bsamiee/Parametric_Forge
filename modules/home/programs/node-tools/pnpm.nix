# Title         : pnpm.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/node-tools/pnpm.nix
# ----------------------------------------------------------------------------
# Performant npm - Fast, disk space efficient package manager

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.pnpm ];
}
