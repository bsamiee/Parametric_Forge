# Title         : taps.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/taps.nix
# ----------------------------------------------------------------------------
# Homebrew tap repositories

{ ... }:

{
  homebrew.taps = [
    "koekeishiya/formulae"  # For yabai/skhd
    "FelixKratz/formulae"   # For borders
  ];
}
