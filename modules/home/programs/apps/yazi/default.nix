# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/yazi
# ----------------------------------------------------------------------------
# Yazi file manager with declarative plugin management

{ config, lib, pkgs, ... }:

let
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "d1c8baab86100afb708694d22b13901b9f9baf00";
    hash = "sha256-52Zn6OSSsuNNAeqqZidjOvfCSB7qPqUeizYq/gO+UbE=";
  };
in
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    plugins = {
      full-border = "${yazi-plugins}/full-border.yazi";
      piper = "${yazi-plugins}/piper.yazi";
      toggle-pane = "${yazi-plugins}/toggle-pane.yazi";
      augment-command = pkgs.fetchFromGitHub {
        owner = "hankertrix";
        repo = "augment-command.yazi";
        rev = "120406f79b6a5bf4db6120dd99c1106008ada5cf";
        hash = "sha256-t9X7cNrMR3fFqiM13COQbBDHYr8UKgxW708V6ndZVgY=";
      };
      easyjump = "${pkgs.fetchFromGitHub {
        owner = "mikavilpas";
        repo = "easyjump.yazi";
        rev = "b77e4f0eecf793a324855de47e3e03393190084c";
        hash = "sha256-QzgnW64XLpm6Vjk6yOBXWWHTJse9pF6ewjEJASAdVu8=";
      }}/easyjump.yazi";
    };
  };

  xdg.configFile = {
    "yazi/yazi.toml".source = ./yazi.toml;
    "yazi/keymap.toml".source = ./keymap.toml;
    "yazi/init.lua".source = ./init.lua;
    "yazi/theme.toml".source = ./theme.toml;

    # --- Custom Plugins -----------------------------------------------------
    "yazi/plugins/auto_layout.yazi/main.lua".source = ./plugins/auto_layout.yazi/main.lua;
    "yazi/plugins/sidebar_status.yazi/main.lua".source = ./plugins/sidebar_status.yazi/main.lua;
  };
}
