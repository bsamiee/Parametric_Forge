# Title         : sd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/sd.nix
# ----------------------------------------------------------------------------
# Intuitive find & replace CLI (sed alternative)
{pkgs, ...}: {
  home.packages = [pkgs.sd];
}
