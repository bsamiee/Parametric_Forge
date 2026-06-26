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

    # --- Server Tools -------------------------------------------------------
    "webhook" # HTTP endpoint for triggering scripts (adnanh/webhook)
  ];
}
