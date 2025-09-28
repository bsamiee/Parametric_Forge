# Title         : trash.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/trash.nix
# ----------------------------------------------------------------------------
# Cross-platform trash command

{ pkgs, ... }:

{
  home.packages = with pkgs; [trash-cli];
}
