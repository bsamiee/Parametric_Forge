# Title         : pandoc.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/pandoc.nix
# ----------------------------------------------------------------------------
# Universal document converter with broad format support

{ pkgs, ... }:

{
  home.packages = [ pkgs.pandoc ];
}
