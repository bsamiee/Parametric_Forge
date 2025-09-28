# Title         : pnpm.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/node-tools/pnpm.nix
# ----------------------------------------------------------------------------
# Performant npm - Fast, disk space efficient package manager

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    pnpm
    nodePackages.npm  # Fallback for legacy projects
  ];

  # pnpm config file with XDG-compliant paths
  xdg.configFile."pnpm/rc".text = ''
    store-dir=${config.xdg.dataHome}/pnpm/store
    cache-dir=${config.xdg.cacheHome}/pnpm
    state-dir=${config.xdg.stateHome}/pnpm
    global-dir=${config.xdg.dataHome}/pnpm/global
    global-bin-dir=${config.xdg.dataHome}/pnpm
  '';
}
