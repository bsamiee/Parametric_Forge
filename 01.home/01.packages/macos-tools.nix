# Title         : macos-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/macos-tools.nix
# ----------------------------------------------------------------------------
# macOS-specific utilities and system tools.

{ pkgs, ... }:

with pkgs;
[
  # --- macOS System Integration ---------------------------------------------
  mas # Mac App Store command-line interface
  _1password-cli # 1Password command-line tool

  # --- macOS Utilities ------------------------------------------------------
  dockutil # Manage macOS dock items
  pngpaste # Paste PNG from clipboard
  duti # Set default applications for document types
  switchaudio-osx # Switch audio sources from CLI
  osx-cpu-temp # Show CPU temperature

  # --- System Management ----------------------------------------------------
  m-cli # Swiss Army Knife for macOS
]
