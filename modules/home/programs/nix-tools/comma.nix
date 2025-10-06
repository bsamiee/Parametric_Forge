# Title         : comma.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/comma.nix
# ----------------------------------------------------------------------------
# Run software without installing: , cowsay "Hello"

{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    comma  # Run software without installing: , cowsay "Hello"
  ];
}
