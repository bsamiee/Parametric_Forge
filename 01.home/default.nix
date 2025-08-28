# Title         : 01.home/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/default.nix
# ----------------------------------------------------------------------------
# Main entry point for home-manager configurations.

{
  lib,
  context ? null,
  ...
}:

{
  # --- Imports ------------------------------------------------------------
  imports = [
    ../modules
    ./01.packages
    ./00.core/programs
    ./tokens.nix
    ./activation.nix
    ./exclusions.nix
    ./xdg.nix
    ./fonts.nix
    ./environment.nix
    ./file-management.nix
  ]
  ++ lib.optionals (context != null) [
    (if context.isDarwin then ./darwin else ./nixos)
  ];
  # --- Core Programs ------------------------------------------------------
  programs.home-manager.enable = true;
}
