# Title         : serpl.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/serpl.nix
# ----------------------------------------------------------------------------
# TUI search and replace powered by ripgrep

{ pkgs, ... }:

let
  serplConfig = ''
    # Title         : config.toml
    # Author        : Bardia Samiee
    # Project       : Parametric Forge
    # License       : MIT
    # Path          : xdg.configHome/serpl/config.toml
    # ----------------------------------------------------------------------------
    # TUI search and replace powered by ripgrep

    [keybindings]
    "<Ctrl-d>" = "Quit"
    "<Ctrl-c>" = "Quit"
    "<Ctrl-q>" = "Quit"
    "<Ctrl-z>" = "Suspend"
    "<Ctrl-r>" = "Refresh"
    "<Ctrl-h>" = "ShowHelp"
    "<Ctrl-o>" = "ProcessReplace"
    "<Tab>" = "LoopOverTabs"
    "<Backtab>" = "BackLoopOverTabs"

  '';
in
{
  home.packages = [ pkgs.serpl ];
  xdg.configFile."serpl/config.toml".text = serplConfig;
}
