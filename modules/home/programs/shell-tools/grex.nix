# Title         : grex.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/grex.nix
# ----------------------------------------------------------------------------
# Regular expression generator from test cases
{pkgs, ...}: {
  home.packages = [pkgs.grex];
}
