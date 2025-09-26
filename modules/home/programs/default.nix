# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/default.nix
# ----------------------------------------------------------------------------
# Home Manager programs aggregator

{ lib, ... }:

{
  imports = [
    ./node-tools
    ./shell-tools
    ./zsh
    # Add other programs here as needed
    # ./git
    # ./nvim
    # ./ssh
  ];
}
