# Title         : inkscape.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/inkscape.nix
# ----------------------------------------------------------------------------
# Inkscape vector graphics editor

{ pkgs, ... }:

{
  # Inkscape stores user preferences under ~/.config/inkscape by default; no extra
  home.packages = [ pkgs.inkscape ];
}
