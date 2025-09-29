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
    # Add nix tools here as needed
    # ./nix-index
    # ./nix-tree
    # ./nixfmt
  ];
}
