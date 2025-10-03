# Title         : brews.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/brews.nix
# ----------------------------------------------------------------------------
# Homebrew CLI tools and formulae

{ ... }:

{
  homebrew.brews = [
    # --- System Utilities ---------------------------------------------------
    "defaultbrowser"                    # CLI tool for setting default browser
    "tag"                               # macOS file tagging CLI
    "blueutil"                          # Bluetooth management
    "mono"                              # .NET runtime

    # --- Window Management Tools --------------------------------------------
    "koekeishiya/formulae/yabai"
    "koekeishiya/formulae/skhd"
    "FelixKratz/formulae/borders"

    # --- Media Tools --------------------------------------------------------
    "handbrake"                         # CLI video transcoder
  ];
}
