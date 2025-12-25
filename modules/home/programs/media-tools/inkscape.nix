# Title         : inkscape.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/inkscape.nix
# ----------------------------------------------------------------------------
# Inkscape vector graphics editor
{pkgs, ...}: {
  home.packages = [pkgs.inkscape];
}
