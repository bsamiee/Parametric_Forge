# Title         : fnm.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/node-tools/fnm.nix
# ----------------------------------------------------------------------------
# Fast Node Manager - Node.js version manager

{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ fnm ];
}