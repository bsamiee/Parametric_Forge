# Title         : rsync.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/rsync.nix
# ----------------------------------------------------------------------------
# File synchronization and transfer utility

{ pkgs, ... }:

{
  home.packages = [ pkgs.rsync ];
}
