# Title         : alejandra.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/alejandra.nix
# ----------------------------------------------------------------------------
# Uncompromising Nix code formatter
{pkgs, ...}: {
  home.packages = [pkgs.alejandra];
}
