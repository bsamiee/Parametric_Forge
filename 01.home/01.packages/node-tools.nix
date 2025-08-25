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
  yarn # Alternative package manager

  # --- Infrastructure & Automation Tools ------------------------------------
  nodePackages.npm-check-updates # Check for dependency updates (ncu command)
  nodePackages.http-server # Simple zero-config HTTP server for testing
  nodePackages.concurrently # Run multiple commands concurrently
  nodePackages.json-server # Quick REST API mock server from JSON files
  nodePackages.serve # Static file server with hot reload

  # --- Code Quality Tools ---------------------------------------------------
  nodePackages.prettier # Code formatter
  nodePackages.eslint # JavaScript linter
  nodePackages.typescript # TypeScript compiler
  nodePackages.typescript-language-server # TypeScript/JavaScript LSP
  nodePackages.vscode-langservers-extracted # JSON/HTML/CSS/ESLint LSPs

  # --- JSON/YAML Tools ------------------------------------------------------
  nodePackages.js-yaml # YAML/JSON converter
  nodePackages.json # JSON manipulation CLI

  # --- AI CLI Tools (Manual Installation) -----------------------------------
  # Not in nixpkgs - install globally via npm:
  # npm install -g @anthropic-ai/claude-code
  # npm install -g @google/gemini-cli
]
