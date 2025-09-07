# Title         : nix-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/nix-tools.nix
# ----------------------------------------------------------------------------
# Nix ecosystem development and maintenance tools.

{ pkgs, ... }:

with pkgs;
[
  # --- Core Nix Toolchain ---------------------------------------------------
  # nixVersions.latest → Using Determinate Systems Nix installation instead
  cachix # Binary cache management (used by cachix-manager script)
  deploy-rs # NixOS deployment tool (used by deploy script)

  # --- Build & Development Tools --------------------------------------------
  nix-output-monitor # Pretty output for Nix builds (used in nb, nd aliases)
  nix-fast-build # Parallel evaluation and building for 90% performance gain
  # nix-index → Managed by programs.nix-index in shell-tools.nix

  # --- Language Server & Code Quality ---------------------------------------
  nil # Nix language server for IDE integration
  deadnix # Find and remove dead code in Nix files
  statix # Lints and suggestions for Nix code
  nixfmt-rfc-style # Official Nix code formatter
]
