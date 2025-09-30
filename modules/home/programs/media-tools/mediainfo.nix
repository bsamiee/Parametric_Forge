# Title         : mediainfo.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/mediainfo.nix
# ----------------------------------------------------------------------------
# Detailed media file information for enhanced Yazi preview

{ pkgs, ... }:

{
  home.packages = [ pkgs.mediainfo ];
}
