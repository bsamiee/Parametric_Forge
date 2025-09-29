# Title         : jq.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/jq.nix
# ----------------------------------------------------------------------------
# Lightweight command-line JSON processor

{ pkgs, ... }:

{
  home.packages = [ pkgs.jq ];
}
