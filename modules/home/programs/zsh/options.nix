# Title         : options.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/options.nix
# ----------------------------------------------------------------------------
# Zsh options and settings

{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    # Keymap
    defaultKeymap = "viins";  # Start in vi insert mode, not command mode

    # Directory navigation
    autocd = true;

    # Completion
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    completionInit = "autoload -U compinit && compinit";

    # History configuration
    history = {
      size = 50000;
      save = 50000;
      path = "${config.xdg.stateHome}/zsh/history";
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };
  };
}
