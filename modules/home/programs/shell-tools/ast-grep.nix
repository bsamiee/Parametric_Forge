# Title         : ast-grep.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/ast-grep.nix
# ----------------------------------------------------------------------------
# Structural code search and rewrite CLI.
{pkgs, ...}: {
  home.packages = with pkgs; [
    ast-grep
  ];
}
