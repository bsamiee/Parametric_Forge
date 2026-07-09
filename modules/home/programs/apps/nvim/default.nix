# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/nvim/default.nix
# ----------------------------------------------------------------------------
# Store-owned Neovim rail: Home Manager wraps neovim-unwrapped and deploys the
# plugin set through xdg data site/pack/hm, so every nvim on the machine --
# including the forge-nvim/forge-edit closure binaries -- loads the same
# pinned plugins with zero network at first start. forge/palette.lua projects
# the estate theme owner (modules/home/theme.nix).
{
  config,
  pkgs,
  ...
}: {
  # defaultEditor projects EDITOR and VISUAL as nvim into home.sessionVariables.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    initLua = builtins.readFile ./init.lua;
    plugins = [
      pkgs.vimPlugins.dracula-vim
      pkgs.vimPlugins.snacks-nvim
    ];
  };

  # Recursive tree link merges tracked sources with the generated palette in
  # one home-files derivation; new Lua files deploy with zero rows here.
  xdg.configFile = {
    "nvim/lua" = {
      source = ./lua;
      recursive = true;
    };
    "nvim/lua/forge/palette.lua".text = config.forge.theme.projections.luaPalette;
  };
}
