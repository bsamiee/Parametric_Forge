# Title         : 00.system/darwin/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/default.nix
# ----------------------------------------------------------------------------
# Import aggregator for all Darwin-specific configuration modules.

{
  # --- Imports --------------------------------------------------------------
  imports = [
    ../default.nix # Universal system configs
    ./darwin.nix # Core Darwin configuration
    ./activation.nix # Activation scripts and exclusions
    ./homebrew.nix # Homebrew and Mac App Store integration
    ./settings/interface.nix # Visual interface and desktop environment
    ./settings/system.nix # Core system behavior and services
    ./settings/input.nix # Input devices: keyboard, mouse, trackpad
    ./settings/security.nix # Security, PAM, certificates
    ./services # Service infrastructure
  ];
}
