# Title         : dotnet-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/dotnet-tools.nix
# ----------------------------------------------------------------------------
# .NET development environment and tooling.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- .NET Runtime & SDK -------------------------------------------------
    dotnet-sdk_7            # .NET SDK 7.0.410 for rhinocode compatibility
  ];
}
