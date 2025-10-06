# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi
# ----------------------------------------------------------------------------
# Yazi file manager with declarative plugin management

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.yazi ];
  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi.toml;
    "yazi/keymap.toml".source = ./keymap.toml;
    "yazi/init.lua".source = ./init.lua;
    "yazi/theme.toml".source = ./theme.toml;

    # --- Custom Plugins -----------------------------------------------------
    "yazi/plugins/auto_layout.yazi/main.lua".source = ./plugins/auto_layout.yazi/main.lua;
    "yazi/plugins/sidebar_status.yazi/main.lua".source = ./plugins/sidebar_status.yazi/main.lua;

    # --- External Plugins ---------------------------------------------------
    "yazi/plugins/full-border.yazi/main.lua".source = ./plugins/full-border.yazi/main.lua;
    "yazi/plugins/eza-preview.yazi".source = pkgs.yaziPlugins.eza-preview;
  };
}
