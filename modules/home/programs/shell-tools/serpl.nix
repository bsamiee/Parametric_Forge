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
  # Bindings added to serpl's own, which it keeps for every key this file leaves unbound.
  xdg.configFile."serpl/config.toml".source = tomlFormat.generate "serpl-config" {
    keybindings = {
      "<Ctrl-q>" = "Quit";
      "<Ctrl-h>" = "ShowHelp";
    };
  };
}
