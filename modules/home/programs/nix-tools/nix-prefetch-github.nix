# Title         : nix-prefetch-github.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/nix-prefetch-github.nix
# ----------------------------------------------------------------------------
# GitHub source prefetching for Nix fetchFromGitHub
{pkgs, ...}: {
  home.packages = with pkgs; [
    nix-prefetch-github
  ];
}
