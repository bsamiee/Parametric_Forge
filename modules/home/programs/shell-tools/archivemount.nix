# Title         : archivemount.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/archivemount.nix
# ----------------------------------------------------------------------------
# FUSE-based mounting for archives (tar/zip/etc.)

{ pkgs, ... }:

{
  home.packages = [ pkgs.archivemount ];
}
