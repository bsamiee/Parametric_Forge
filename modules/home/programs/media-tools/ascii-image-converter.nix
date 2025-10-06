# Title         : ascii-image-converter.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/ascii-image-converter.nix
# ----------------------------------------------------------------------------
# Convert images to ASCII art in terminal

{ pkgs, ... }:

{
  home.packages = [ pkgs.ascii-image-converter ];
}
