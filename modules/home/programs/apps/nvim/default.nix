# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/nvim/default.nix
# ----------------------------------------------------------------------------
# Neovim configuration entry point

{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    neovim-remote
  ];

  xdg.configFile = {
    "nvim/init.lua".source = ./init.lua;
    "nvim/lua".source = ./lua;
  };
}
