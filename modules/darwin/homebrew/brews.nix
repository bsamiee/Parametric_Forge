# Title         : brews.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/brews.nix
# ----------------------------------------------------------------------------
# Homebrew CLI tools and formulae
_: {
  homebrew.brews = [
    # --- System Utilities ---------------------------------------------------
    "fnm" # Fast Node version manager (per-project Node versions)
    "defaultbrowser" # CLI tool for setting default browser
    "tag" # macOS file tagging CLI
    "blueutil" # Bluetooth management

    # --- Window Management Tools --------------------------------------------
    "asmvik/formulae/yabai"
    "asmvik/formulae/skhd"
    "FelixKratz/formulae/borders"

    # --- Server Tools -------------------------------------------------------
    "webhook" # HTTP endpoint for triggering scripts (adnanh/webhook)
  ];
}
