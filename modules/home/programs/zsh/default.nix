# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/default.nix
# ----------------------------------------------------------------------------
# Zsh configuration orchestrator

{ config, lib, pkgs, ... }:

{
  imports = [
    ./init.nix
    ./plugins.nix
    ./options.nix
    ./config.nix
    ../../aliases
  ];

  programs.zsh = {
    enable = true;
    # Remove dotDir - it causes session variables to be written to .config/zsh/.zprofile
    # instead of hm-session-vars.sh where they belong
  };
}
