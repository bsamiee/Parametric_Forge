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
    "defaultbrowser" # CLI tool for setting default browser
    "tag" # macOS file tagging CLI
    "blueutil" # Bluetooth management
    "pinentry-mac" # GUI sudo prompt for the brew autoupdate agent

    # --- Server Tools -------------------------------------------------------
    "webhook" # HTTP endpoint for triggering scripts (adnanh/webhook)
  ];
}
