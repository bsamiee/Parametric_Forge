# Title         : node-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/node-tools.nix
# ----------------------------------------------------------------------------
# Node.js development environment and tooling.

{ pkgs, ... }:

with pkgs;
[
  # --- Node.js Toolchain ----------------------------------------------------
  nodejs_22 # Node.js runtime
  pnpm # Fast, disk space efficient package manager

  # --- Infrastructure & Automation Tools ------------------------------------
  nodePackages.npm-check-updates # Check for dependency updates (ncu command)
  nodePackages.http-server # Simple zero-config HTTP server for testing
  nodePackages.concurrently # Run multiple commands concurrently
  nodePackages.serve # Static file server with hot reload

  # --- Code Quality Tools ---------------------------------------------------
  nodePackages.prettier # Code formatter
  nodePackages.vscode-langservers-extracted # JSON/HTML/CSS LSPs

  # --- JSON/YAML Tools ------------------------------------------------------
  nodePackages.js-yaml # YAML/JSON converter
  nodePackages.json # JSON manipulation CLI
]
