# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/default.nix
# ----------------------------------------------------------------------------
# Nix tools aggregator

{ lib, ... }:

{
  imports = [
    ./nix-index.nix
    ./nom.nix
  ];
}
