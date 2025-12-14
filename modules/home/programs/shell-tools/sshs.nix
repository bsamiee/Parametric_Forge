# Title         : sshs.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/sshs.nix
# ----------------------------------------------------------------------------
# sshs: Lightweight terminal UI for SSH host selection
# Reads ~/.ssh/config and provides fuzzy search for quick connections

{ pkgs, ... }:

{
  home.packages = [ pkgs.sshs ];
}
