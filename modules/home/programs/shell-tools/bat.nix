# Title         : bat.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/bat.nix
# ----------------------------------------------------------------------------
# Cat clone with syntax highlighting and Git integration

{ config, lib, pkgs, ... }:

{
  programs.bat = {
    enable = true;

    config = {
      # Theme handled by Stylix auto-theming
      # Display configuration
      style = "numbers,changes,header,grid";
      wrap = "character";
      tabs = "4";

      # Syntax mappings for unrecognized extensions
      map-syntax = [
        "*.nix:Nix"
        ".envrc:Bash"
        "*.jenkinsfile:Groovy"
        "*.jsonc:JSON"
      ];
    };

    extraPackages = with pkgs.bat-extras; [
      batdiff      # Diff with syntax highlighting
      batman       # Colored man pages
      batgrep      # Ripgrep wrapper with bat preview
      batwatch     # Watch files with bat
      prettybat    # Pretty-print and format code
      batpipe      # Less preprocessor for bat
    ];
  };
}
