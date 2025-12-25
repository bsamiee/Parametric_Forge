# Title         : git-quick-stats.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/git-quick-stats.nix
# ----------------------------------------------------------------------------
# Git statistics tool for comprehensive repository analytics
{pkgs, ...}: {
  home.packages = [pkgs.git-quick-stats];
}
