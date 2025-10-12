# Title         : deadnix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/deadnix.nix
# ----------------------------------------------------------------------------
# Dead code finder for Nix - removes unused variable bindings

{ pkgs, ... }:

{
  home.packages = [ pkgs.deadnix ];
}
