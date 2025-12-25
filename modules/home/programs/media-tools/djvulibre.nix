# Title         : djvulibre.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/djvulibre.nix
# ----------------------------------------------------------------------------
# DjVu document support required by djvu-view.yazi plugin
{pkgs, ...}: {
  home.packages = [pkgs.djvulibre];
}
