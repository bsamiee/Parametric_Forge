# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/default.nix
# ----------------------------------------------------------------------------
# macOS-specific tool configurations
{...}: {
  imports = [
    ./duti.nix
    # Future macOS tools:
    # ./raycast.nix    # Raycast configuration
    # ./shortcuts.nix  # Shortcuts automation
  ];
}
