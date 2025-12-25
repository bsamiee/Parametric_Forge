# Title         : statix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/statix.nix
# ----------------------------------------------------------------------------
# Statix linter for Nix code - finds antipatterns and suggests fixes
{pkgs, ...}: {
  home.packages = [pkgs.statix];
}
