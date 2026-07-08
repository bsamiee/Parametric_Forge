# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/nvim/default.nix
# ----------------------------------------------------------------------------
# Neovim configuration entry point
{pkgs, ...}: {
  home.packages = [pkgs.neovim];

  xdg.configFile = {
    "nvim/init.lua".source = ./init.lua;
    "nvim/lua".source = ./lua;
  };
}
