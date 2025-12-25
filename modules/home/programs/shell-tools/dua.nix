# Title         : dua.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/dua.nix
# ----------------------------------------------------------------------------
# Disk usage analyzer with interactive deletion mode
{pkgs, ...}: {
  home.packages = [pkgs.dua];
}
