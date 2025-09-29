# Title         : doggo.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/doggo.nix
# ----------------------------------------------------------------------------
# Modern DNS client with human-friendly output

{ pkgs, ... }:

{
  home.packages = [ pkgs.doggo ];
}
