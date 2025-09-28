# Title         : plugins.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/plugins.nix
# ----------------------------------------------------------------------------
# Zsh plugin management - home-manager native approach

{ config, lib, pkgs, ... }:

{
  programs.zsh.plugins = [
    {
      name = "fzf-tab";
      src = pkgs.zsh-fzf-tab;
      file = "share/fzf-tab/fzf-tab.plugin.zsh";
    }
    {
      name = "forgit";
      src = pkgs.zsh-forgit;
      file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
    }
    {
      name = "you-should-use";
      src = pkgs.zsh-you-should-use;
      file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
    }
  ];
}
