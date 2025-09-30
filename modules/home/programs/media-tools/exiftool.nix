# Title         : exiftool.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/exiftool.nix
# ----------------------------------------------------------------------------
# Read/write metadata in media files for Yazi audio preview

{ pkgs, ... }:

{
  home.packages = [ pkgs.exiftool ];
}
