# Title         : sd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/sd.nix
# ----------------------------------------------------------------------------
# Intuitive find & replace CLI (sed alternative)
# sd doesn't have a programs.sd module - it's a simple CLI tool

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.sd ];
}
