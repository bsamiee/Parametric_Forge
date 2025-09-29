# Title         : gping.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/gping.nix
# ----------------------------------------------------------------------------
# Ping with real-time graph visualization

{ pkgs, ... }:

{
  home.packages = [ pkgs.gping ];
}
