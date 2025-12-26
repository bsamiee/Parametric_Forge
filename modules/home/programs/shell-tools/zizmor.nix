# Title         : zizmor.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/zizmor.nix
# ----------------------------------------------------------------------------
# GitHub Actions security scanner (template injection, credential exposure)
{pkgs, ...}: {
  home.packages = [pkgs.zizmor];
}
