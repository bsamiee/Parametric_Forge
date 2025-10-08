# Title         : rich-cli.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/rich-cli.nix
# ----------------------------------------------------------------------------
# Rich command-line interface for rendering and inspecting content with Dracula theme

{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    rich-cli
  ];
}
