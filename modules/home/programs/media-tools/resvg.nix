# Title         : resvg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/resvg.nix
# ----------------------------------------------------------------------------
# SVG rendering library required by Yazi for SVG preview
{pkgs, ...}: {
  home.packages = [pkgs.resvg];
}
