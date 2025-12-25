# Title         : bat.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/bat.nix
# ----------------------------------------------------------------------------
# Cat clone with syntax highlighting and Git integration
{pkgs, ...}: {
  programs.bat = {
    enable = true;

    config = {
      theme = "Dracula";
      style = "numbers,changes,header,grid";
      wrap = "character";
      tabs = "4";
      paging = "auto"; # Let pager work normally

      # Syntax mappings for unrecognized extensions
      map-syntax = [
        "*.nix:Nix"
        ".envrc:Bash"
        "*.jenkinsfile:Groovy"
        "*.jsonc:JSON"
      ];
    };

    extraPackages = with pkgs.bat-extras; [
      batman # Colored man pages
      batgrep # Ripgrep wrapper with bat preview
    ];
  };
}
