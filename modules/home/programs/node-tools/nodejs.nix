# Title         : nodejs.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/node-tools/nodejs.nix
# ----------------------------------------------------------------------------
# Node.js JavaScript runtime

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.nodejs ];
}
