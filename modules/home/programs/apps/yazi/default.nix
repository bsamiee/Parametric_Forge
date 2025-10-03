# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi
# ----------------------------------------------------------------------------
# Yezi file manager configuration

{ pkgs, ... }:

{
  home.packages = [ pkgs.yazi ];
}
