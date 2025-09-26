# Title         : zoxide.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/zoxide.nix
# ----------------------------------------------------------------------------
# Smart directory navigation with frecency-based learning

{ config, lib, pkgs, ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;

    options = [
      "--cmd=cd"       # Replace cd command entirely
      "--hook=prompt"  # Update frecency based on time spent (better than pwd)
    ];
  };
}
