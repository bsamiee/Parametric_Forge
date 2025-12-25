# Title         : actionlint.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/actionlint.nix
# ----------------------------------------------------------------------------
# GitHub Actions workflow linter
{pkgs, ...}: {
  home.packages = [pkgs.actionlint];
}
