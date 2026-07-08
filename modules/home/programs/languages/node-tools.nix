# Title         : node-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/node-tools.nix
# ----------------------------------------------------------------------------
# Node.js runtime and package tooling.
{pkgs, ...}: {
  home.packages = [
    pkgs.nodejs-bin_26 # Official Node 26 Darwin binary, npm/npx/corepack stripped in-overlay
    pkgs.pnpm_11 # Sole package-manager verb on PATH; major-pinned for store-format stability
    pkgs.prettier # Code formatter
    pkgs.tailwindcss # Utility-first CSS framework
    pkgs.typescript-go # TypeScript native-preview LSP (provides `tsgo`)
    pkgs.dts-lsp # TypeScript declaration navigation for API catalogue work
    pkgs.mermaid-cli # Mermaid CLI (mmdc) on PATH; Chromium pinned via PUPPETEER_EXECUTABLE_PATH in languages.nix
  ];
}
