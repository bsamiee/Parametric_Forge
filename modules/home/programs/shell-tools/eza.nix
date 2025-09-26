# Title         : eza.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/eza.nix
# ----------------------------------------------------------------------------
# Modern ls replacement with colors and icons

{ config, lib, pkgs, ... }:

{
  programs.eza = {
    enable = true;
    enableZshIntegration = true;

    git = true;
    icons = "always";

    extraOptions = [
      "--color=always"
      "--group-directories-first"
      "--header"
      "--hyperlink"               # Clickable files in terminal
      "--links"                   # Show hard link count
      "--sort=name"               # Sort by filename
      "--time-style=iso"          # 24-hour format: 2024-01-01 14:30
    ];
  };
}
