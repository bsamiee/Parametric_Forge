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
    # --- System utilities ---------------------------------------------------
    "defaultbrowser"                    # CLI tool for setting default browser
    "tag"                               # macOS file tagging CLI
    "blueutil"                          # Bluetooth management
    "mono"                              # .NET runtime

    # --- Window management tools --------------------------------------------
    "koekeishiya/formulae/yabai"
    "koekeishiya/formulae/skhd"
    "FelixKratz/formulae/borders"
    "yqrashawn/goku/goku"               # Karabiner EDN compiler

    # --- Media tools --------------------------------------------------------
    "handbrake"                         # CLI video transcoder
  ];
}
