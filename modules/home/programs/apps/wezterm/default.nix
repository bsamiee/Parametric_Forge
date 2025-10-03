# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/wezterm/default.nix
# ----------------------------------------------------------------------------
# WezTerm terminal emulator configuration

{ config, lib, pkgs, ... }:

{
  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "wezterm/appearance.lua".source = ./appearance.lua;
    "wezterm/behavior.lua".source = ./behavior.lua;
    "wezterm/keys.lua".source = ./keys.lua;
    "wezterm/mouse.lua".source = ./mouse.lua;
    "wezterm/integration.lua".source = ./integration.lua;
  };
}
