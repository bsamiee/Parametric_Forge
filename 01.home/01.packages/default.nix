# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/default.nix
# ----------------------------------------------------------------------------
# Package aggregator - all packages enabled by default.

{
  lib,
  pkgs,
  ...
}:

let
  # --- Import all package modules ------------------------------------
  allPackageModules = {
    core = import ./core.nix { inherit pkgs; };
    nixTools = import ./nix-tools.nix { inherit pkgs; };
    devTools = import ./dev-tools.nix { inherit pkgs; };
    sysadmin = import ./sysadmin.nix { inherit pkgs; };
    devops = import ./devops.nix { inherit pkgs; };
    media = import ./media-tools.nix { inherit pkgs; };
    aiTools = import ./ai-tools.nix { inherit pkgs; };
    python = import ./python-tools.nix { inherit pkgs; };
    rust = import ./rust-tools.nix { inherit pkgs; };
    node = import ./node-tools.nix { inherit pkgs; };
    lua = import ./lua-tools.nix { inherit pkgs; };
  };

in
{
  home.packages = lib.flatten [
    # --- Core Packages ---------------------------------------------
    allPackageModules.core
    allPackageModules.nixTools
    allPackageModules.devTools

    # --- System Tools ----------------------------------------------
    allPackageModules.sysadmin
    allPackageModules.devops
    allPackageModules.media
    allPackageModules.aiTools

    # --- Development Languages -------------------------------------
    allPackageModules.python
    allPackageModules.rust
    allPackageModules.node
    allPackageModules.lua
  ];
}
