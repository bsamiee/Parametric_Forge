# Title         : node-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/node-tools.nix
# ----------------------------------------------------------------------------
# Node.js runtime and package tooling.
{pkgs, ...}: {
  home.packages = with pkgs; [
    nodejs_26 # Current nixpkgs Node line for agents and non-interactive tools
    pnpm_11 # Major-pinned package manager for PATH and store-format stability
    prettier # Code formatter
    tailwindcss # Utility-first CSS framework
    typescript-go # TypeScript native-preview LSP (provides `tsgo`)
    dts-lsp # TypeScript declaration navigation for API catalogue work
  ];
}
