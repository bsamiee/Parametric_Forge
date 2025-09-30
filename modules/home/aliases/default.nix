# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/default.nix
# ----------------------------------------------------------------------------
# Shell aliases aggregator

{ lib, ... }:

{
  imports = [
    ./core.nix
    ./media.nix
    ./nix.nix
  ];
}
