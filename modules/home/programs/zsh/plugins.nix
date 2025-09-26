# Title         : plugins.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/plugins.nix
# ----------------------------------------------------------------------------
# Zsh plugin management - clean nixpkgs approach

{ config, lib, pkgs, ... }:

{
  # Clean approach: use nixpkgs packages instead of fetchFromGitHub
  home.packages = with pkgs; [
    zsh-fzf-tab        # Replace zsh's tab completion with fzf
    zsh-forgit         # Git object browser powered by fzf
    zsh-you-should-use # Reminds you to use existing aliases
    zsh-completions    # Additional completion definitions
  ];
}
