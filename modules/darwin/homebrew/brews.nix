# Title         : brews.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/brews.nix
# ----------------------------------------------------------------------------
# Homebrew CLI tools and formulae

_: {
  homebrew.brews = [
    # --- [SYSTEM_UTILITIES]
    "defaultbrowser" # CLI tool for setting default browser
    "tag" # macOS file tagging CLI
    "blueutil" # Bluetooth management
    "pinentry-mac" # Keychain-backed sudo askpass for the brew autoupdate agent

    # --- [CONTAINER_RUNTIMES]
    "container" # Apple Container; requires macOS 26 (arm64); coexistence runtime, never DOCKER_HOST owner
  ];
}
