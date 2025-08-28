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
  sysadminAliases = import ./sysadmin.nix { };
  devToolsAliases = (import ./dev-tools.nix { inherit lib; }).aliases;
  devopsAliases = (import ./devops.nix { inherit lib; }).aliases;
  mediaAliases = (import ./media.nix { inherit lib; }).aliases;
  gitAliases = import ./git.nix { };
  nixAliases = import ./nix.nix { };
  rustAliases = import ./rust.nix { };
  luaAliases = import ./lua.nix { };
  shellAliases = import ./shell.nix { };
  macosAliases = import ./macos.nix { };

in
lib.mkMerge [
  coreAliases
  sysadminAliases
  devToolsAliases
  devopsAliases
  mediaAliases
  gitAliases
  nixAliases
  rustAliases
  luaAliases
  shellAliases
  macosAliases
]
