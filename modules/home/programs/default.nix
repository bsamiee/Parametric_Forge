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
    ./apps
    ./mac-tools
    ./media-tools
    ./languages
    ./shell-tools
    ./git-tools
    ./nix-tools
    ./zsh
  ];
}
