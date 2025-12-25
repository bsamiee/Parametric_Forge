# Title         : chafa.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/chafa.nix
# ----------------------------------------------------------------------------
# Terminal graphics for fallback image preview in Yazi
{pkgs, ...}: {
  home.packages = [pkgs.chafa];
}
