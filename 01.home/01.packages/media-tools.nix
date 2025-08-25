# Title         : media-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/media-tools.nix
# ----------------------------------------------------------------------------
# Media processing and manipulation tools.

{ pkgs, ... }:

with pkgs;
[
  # --- Media Processing Tools -----------------------------------------------
  ffmpeg # Complete multimedia framework
  imagemagick # Image manipulation
  yt-dlp # Video downloader
  pandoc # Universal document converter
  graphviz # Graph visualization software
]
