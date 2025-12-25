# Title         : hexyl.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/hexyl.nix
# ----------------------------------------------------------------------------
# Hexyl - colored command-line hex viewer
{pkgs, ...}: {
  home.packages = [pkgs.hexyl];
}
