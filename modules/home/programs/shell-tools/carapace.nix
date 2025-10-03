# Title         : carapace.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/carapace.nix
# ----------------------------------------------------------------------------
# Multi-shell argument completion binary

{ config, lib, pkgs, ... }:

{
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableNushellIntegration = false;
  };
}
