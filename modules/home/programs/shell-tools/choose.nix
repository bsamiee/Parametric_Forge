# Title         : choose.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/choose.nix
# ----------------------------------------------------------------------------
# Human-friendly alternative to cut and awk

{ pkgs, ... }:

{
  home.packages = [ pkgs.choose ];
}
