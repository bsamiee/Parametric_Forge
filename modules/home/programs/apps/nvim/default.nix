# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/nvim/default.nix
# ----------------------------------------------------------------------------
# Neovim configuration entry point; forge/palette.lua is generated from the
# estate palette owner (modules/home/theme.nix)
{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.neovim];

  xdg.configFile = {
    "nvim/init.lua".source = ./init.lua;
    "nvim/lua" = {
      source = ./lua;
      recursive = true;
    };
    "nvim/lua/forge/palette.lua".text = config.forge.theme.projections.luaPalette;
  };
}
