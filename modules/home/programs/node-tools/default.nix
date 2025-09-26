# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/node-tools/default.nix
# ----------------------------------------------------------------------------
# Node.js tools aggregator

{ lib, ... }:

{
  imports = [
    ./fnm.nix
    ./nodejs.nix
    ./pnpm.nix
  ];
}
