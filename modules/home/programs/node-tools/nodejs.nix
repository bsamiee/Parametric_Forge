# Title         : nodejs.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/node-tools/nodejs.nix
# ----------------------------------------------------------------------------
# Node.js JavaScript runtime

{ pkgs, ... }:

{
  home.packages = [ pkgs.nodejs_20 ];  # LTS version - better cache support
}
