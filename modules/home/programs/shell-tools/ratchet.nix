# Title         : ratchet.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/ratchet.nix
# ----------------------------------------------------------------------------
# GitHub Actions version pinning and SHA linting
{pkgs, ...}: {
  home.packages = [pkgs.ratchet];
}
