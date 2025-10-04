# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/default.nix
# ----------------------------------------------------------------------------
# GUI and terminal applications aggregator

{ lib, ... }:

{
  imports = [
    #./karabiner - #TODO: Make a proper configuration for Karabiner-Elements
    ./wezterm
    ./yazi
    ./zellij
  ];
}
