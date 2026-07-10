# Title         : serpl.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/serpl.nix
# ----------------------------------------------------------------------------
# TUI search and replace powered by ripgrep

{pkgs, ...}: let
  tomlFormat = pkgs.formats.toml {};
in {
  home.packages = [pkgs.serpl];
  xdg.configFile."serpl/config.toml".source = tomlFormat.generate "serpl-config" {
    keybindings = {
      "<Ctrl-d>" = "Quit";
      "<Ctrl-c>" = "Quit";
      "<Ctrl-q>" = "Quit";
      "<Ctrl-z>" = "Suspend";
      "<Ctrl-r>" = "Refresh";
      "<Ctrl-h>" = "ShowHelp";
      "<Ctrl-o>" = "ProcessReplace";
      "<Tab>" = "LoopOverTabs";
      "<Backtab>" = "BackLoopOverTabs";
    };
  };
}
