# Title         : mas.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/mas.nix
# ----------------------------------------------------------------------------
# Mac App Store command-line interface

{ pkgs, ... }:

{
  home.packages = [ pkgs.mas ];
}
