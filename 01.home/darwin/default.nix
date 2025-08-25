# Title         : 01.home/darwin/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/default.nix
# ----------------------------------------------------------------------------
# Darwin-specific home-manager configuration.

{ pkgs, ... }:

{
  imports = [
    ./activation.nix
    ./services # User-level launchd agents
  ];

  # --- Platform Assertion ---------------------------------------------------
  assertions = [
    {
      assertion = pkgs.stdenv.isDarwin;
      message = "01.home/darwin/default.nix should only be used on Darwin systems";
    }
  ];

  # --- Darwin-Specific Settings ---------------------------------------------
  # Programs will be imported from modules/programs/
  # Aliases will be imported from modules/aliases/

  # --- macOS Application Support --------------------------------------------
  # Platform-specific variables can be defined here when needed
}
