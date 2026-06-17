# Title         : nixd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/nixd.nix
# ----------------------------------------------------------------------------
# nixd language server for Nix - completion, diagnostics, and navigation
{pkgs, ...}: {
  home.packages = [pkgs.nixd];
}
