# Title         : imagemagick.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/imagemagick.nix
# ----------------------------------------------------------------------------
# ImageMagick 7 image manipulation suite
{pkgs, ...}: {
  home.packages = [pkgs.imagemagick];
}
