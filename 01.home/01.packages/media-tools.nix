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
  # pandoc → Managed by programs.pandoc in media-tools.nix (programs dir)
  graphviz # Graph visualization software
]
