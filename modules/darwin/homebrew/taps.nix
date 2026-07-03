# Title         : taps.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/taps.nix
# ----------------------------------------------------------------------------
# Homebrew tap repositories
_: {
  homebrew.taps = [
    "domt4/autoupdate" # brew autoupdate launchd agent; daemon state stays operator-owned
  ];
}
