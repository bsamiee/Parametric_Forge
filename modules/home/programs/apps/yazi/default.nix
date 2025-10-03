# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi
# ----------------------------------------------------------------------------
# PLACEHOLDER

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.yazi ];
  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi.toml;
    "yazi/keymap.toml".source = ./keymap.toml;
    "yazi/init.lua".source = ./init.lua;
    "yazi/plugins/auto_layout.yazi/main.lua".source = ./plugins/auto_layout.yazi/main.lua;
    "yazi/plugins/sidebar_status.yazi/main.lua".source = ./plugins/sidebar_status.yazi/main.lua;
  };

}
