# Title         : node-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/node-tools.nix
# ----------------------------------------------------------------------------
# Node.js runtime, version manager, and package tooling.

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_22 # Latest LTS for modern TypeScript/React projects
    fnm       # Fast Node Manager for multi-version workflows
    pnpm      # Disk-efficient package manager
    nodePackages.prettier # Code formatter
    tailwindcss # Utility-first CSS framework
  ];

  # --- pnpm Configuration ---------------------------------------------------
  xdg.configFile."pnpm/rc".text = ''
    store-dir=${config.xdg.dataHome}/pnpm/store
    cache-dir=${config.xdg.cacheHome}/pnpm
    state-dir=${config.xdg.stateHome}/pnpm
    global-dir=${config.xdg.dataHome}/pnpm/global
    global-bin-dir=${config.xdg.dataHome}/pnpm
  '';
}
