# Title         : node-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/node-tools.nix
# ----------------------------------------------------------------------------
# Node.js runtime and package tooling.
{pkgs, ...}: {
  home.packages = with pkgs; [
    pnpm_10 # Package manager - nix-managed for PATH stability
    nodePackages.prettier # Code formatter
    tailwindcss # Utility-first CSS framework
  ];
}
