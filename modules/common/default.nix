# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/default.nix
# ----------------------------------------------------------------------------
# Common configuration aggregator

{ ... }:

{
  imports = [
    ./nix.nix
    ./theme.nix
  ];
}
