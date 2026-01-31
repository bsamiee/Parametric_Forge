# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/default.nix
# ----------------------------------------------------------------------------
# Zsh configuration orchestrator
{config, ...}: {
  imports = [
    ./init.nix
    ./plugins.nix
    ./options.nix
    ./config.nix
    ../../aliases
  ];

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
  };
}
