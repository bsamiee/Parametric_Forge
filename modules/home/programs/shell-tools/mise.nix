# Title         : mise.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/mise.nix
# ----------------------------------------------------------------------------
# Polyglot runtime manager and task runner; Hydra-cached nixpkgs package.
{pkgs, ...}: {
  home.packages = [pkgs.mise];
}
