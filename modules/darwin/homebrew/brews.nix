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
    "tag" # macOS file tagging CLI
    "blueutil" # Bluetooth management

    # --- [REVIEWERS]
    "greptileai/tap/greptile" # Official Greptile CLI; the qualified name scopes the module's default trust to this formula, not the tap

    # --- [CONTAINER_RUNTIMES]
    "container" # Apple Container; requires macOS 26 (arm64); coexistence runtime, never DOCKER_HOST owner
  ];
}
