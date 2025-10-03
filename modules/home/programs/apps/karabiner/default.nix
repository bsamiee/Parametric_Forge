# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/karabiner/default.nix
# ----------------------------------------------------------------------------
# Karabiner-Elements complex modifications deployment

{ config, lib, ... }:

{
  xdg.configFile."karabiner/assets/complex_modifications/leader_keys.json".source = ./leader_keys.json;
}
