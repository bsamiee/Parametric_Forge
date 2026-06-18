# Title         : taps.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/taps.nix
# ----------------------------------------------------------------------------
# Homebrew tap repositories
_: {
  homebrew.taps = [
    {
      name = "asmvik/formulae"; # For yabai/skhd
      trusted = true;
    }
    {
      name = "FelixKratz/formulae"; # For borders
      trusted = true;
    }
  ];
}
