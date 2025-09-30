# Title         : transmission.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/transmission.nix
# ----------------------------------------------------------------------------
# Transmission 4 BitTorrent client (CLI + daemon tooling)

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs.transmission_4 ];
}
