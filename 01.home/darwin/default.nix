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
    ./services
  ];

  # --- Platform Assertion ---------------------------------------------------
  assertions = [
    {
      assertion = pkgs.stdenv.isDarwin;
      message = "01.home/darwin/default.nix should only be used on Darwin systems";
    }
  ];
}
