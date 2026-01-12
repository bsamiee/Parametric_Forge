# Title         : node-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/node-tools.nix
# ----------------------------------------------------------------------------
# Node.js runtime, version manager, and package tooling.
{pkgs, ...}: {
  home.packages = with pkgs; [
    nodejs_22 # Fallback LTS; fnm manages active version via .node-version
    fnm # Fast Node Manager - prepends managed node to PATH
    pnpm_10 # Package manager - nix-managed for PATH stability
    nodePackages.prettier # Code formatter
    tailwindcss # Utility-first CSS framework
  ];
}
