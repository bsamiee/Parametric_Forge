# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/default.nix
# ----------------------------------------------------------------------------
# Aggregates all shell aliases from various modules.

{ lib, ... }:

let
  # Import all alias modules
  coreAliases = import ./core.nix { };
  devToolsAliases = (import ./dev-tools.nix { inherit lib; }).aliases;
  gitAliases = (import ./git.nix { inherit lib; }).aliases;
  macosAliases = import ./macos.nix { };

in
lib.mkMerge [
  coreAliases
  devToolsAliases
  gitAliases
  macosAliases
]
