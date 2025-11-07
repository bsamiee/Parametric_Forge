# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/default.nix
# ----------------------------------------------------------------------------
# Darwin module aggregator

{ lib, ... }:

{
  imports = [
    ./fonts.nix
    ./environment.nix
    ./homebrew
    ./settings
  ];
}
