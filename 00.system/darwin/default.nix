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
    ../default.nix
    ./darwin.nix
    ./activation.nix
    ./homebrew.nix
    ./applications.nix
    ./settings/interface.nix
    ./settings/system.nix
    ./settings/input.nix
    ./settings/security.nix
    ./services
  ];
}
