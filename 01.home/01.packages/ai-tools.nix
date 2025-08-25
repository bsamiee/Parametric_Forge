# Title         : ai-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/ai-tools.nix
# ----------------------------------------------------------------------------
# AI-powered development and productivity tools.

{ pkgs, ... }:

with pkgs;
[
  # --- AI Development Tools ------------------------------------------------
  claude-code # Agentic coding tool that lives in your terminal

  # --- AI Productivity Tools -----------------------------------------------
  # Additional AI tools can be added here as they become available in nixpkgs
]