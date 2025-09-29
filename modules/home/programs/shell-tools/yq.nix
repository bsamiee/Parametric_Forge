# Title         : yq.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/yq.nix
# ----------------------------------------------------------------------------
# Portable command-line YAML, JSON, XML, CSV, TOML processor

{ pkgs, ... }:

{
  home.packages = [ pkgs.yq-go ];
}
