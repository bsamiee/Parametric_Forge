# Title         : curlie.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/curlie.nix
# ----------------------------------------------------------------------------
# Curl frontend with HTTPie ease of use

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.curlie ];
}