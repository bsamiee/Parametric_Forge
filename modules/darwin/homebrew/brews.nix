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

    # --- [REVIEWERS]
    {
      name = "greptileai/tap/greptile"; # Official Greptile CLI tap; native updater and Homebrew share custody
      trusted = true; # Homebrew 6 tap trust, scoped to this formula rather than the whole tap
    }

    # --- [CONTAINER_RUNTIMES]
    "container" # Apple Container; requires macOS 26 (arm64); coexistence runtime, never DOCKER_HOST owner
  ];
}
