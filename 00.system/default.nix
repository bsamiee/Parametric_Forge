# Title         : 00.system/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/default.nix
# ----------------------------------------------------------------------------
# Universal system-level module aggregation.

{ ... }:

{
  # --- Universal Imports ----------------------------------------------------
  imports = [
    ./environment.nix
    ./fonts.nix
    ./nix.nix
    ./cachix.nix
  ];
}
