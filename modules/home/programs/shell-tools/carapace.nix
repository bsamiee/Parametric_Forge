# Title         : carapace.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/carapace.nix
# ----------------------------------------------------------------------------
# Multi-shell argument completion binary
#
# Known Issues:
# - Double-escaping bug with fzf-tab for files with special characters
#   (see: https://github.com/Aloxaf/fzf-tab/issues/503)
# - Workaround: Use '**' tab completion for problematic files

{ config, lib, pkgs, ... }:

{
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;  # Only enable shells we use
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableNushellIntegration = false;
  };
}
