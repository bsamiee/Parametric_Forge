# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/apps/default.nix
# ----------------------------------------------------------------------------
# GUI and terminal applications aggregator

{ lib, ... }:

{
  imports = [
    ./wezterm
    ./zellij
    # Future GUI/TUI apps here:
    # ./alacritty
    # ./kitty
    # ./neovide
    # ./vscode
  ];
}
