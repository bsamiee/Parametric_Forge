# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/assets/default.nix
# ----------------------------------------------------------------------------
# Asset files aggregator - logos, images, fonts, and other binary assets

{ lib, ... }:

{
  imports = [
    ./ascii
  ];
}
