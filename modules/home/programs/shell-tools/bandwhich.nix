# Title         : bandwhich.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/bandwhich.nix
# ----------------------------------------------------------------------------
# Terminal bandwidth utilization monitor

{ pkgs, ... }:

{
  home.packages = [ pkgs.bandwhich ];
}
