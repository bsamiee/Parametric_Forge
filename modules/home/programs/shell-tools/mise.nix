# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# Polyglot runtime manager (Node, Python, Ruby, etc.) and task runner
{pkgs, ...}: {
  home.packages = [pkgs.mise];
}
