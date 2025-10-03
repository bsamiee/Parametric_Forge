# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/default.nix
# ----------------------------------------------------------------------------
# Home Manager module aggregator

{ lib, ... }:

{
  imports = [
    ./environments
    ./programs
    ./scripts
    ./xdg.nix
  ];
}
