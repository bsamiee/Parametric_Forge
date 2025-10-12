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
    ./alejandra.nix
    ./comma.nix
    ./deadnix.nix
    ./nix-index.nix
    ./nix-prefetch-github.nix
    ./nom.nix
    ./statix.nix
  ];
}
