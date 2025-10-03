# Title         : zesh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/zesh.nix
# ----------------------------------------------------------------------------
# Zellij session manager with zoxide integration

{ pkgs, ... }:

{
  home.packages = [ pkgs.zesh ];
}