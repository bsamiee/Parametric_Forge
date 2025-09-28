# Title         : duf.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/duf.nix
# ----------------------------------------------------------------------------
# Modern disk usage/free utility (df replacement)

{ pkgs, ... }:

{
  home.packages = [ pkgs.duf ];
}
