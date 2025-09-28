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
    # --- Directory navigation -----------------------------------------------
    autocd = true;

    # --- Completion ---------------------------------------------------------
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # --- History ------------------------------------------------------------
    history = {
      size = 50000;
      save = 50000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };
  };
}
