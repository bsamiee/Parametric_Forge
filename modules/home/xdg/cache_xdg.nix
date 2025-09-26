# Title         : cache_xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg/cache_xdg.nix
# ----------------------------------------------------------------------------
# XDG_CACHE_HOME directory structure

{ config, lib, ... }:

{
  home.activation.createCacheDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Cache directories for system-critical components only

    # --- Core System --------------------------------------------------------
    mkdir -pm 755 "${config.xdg.cacheHome}/nix"         # Nix evaluation cache
    mkdir -pm 755 "${config.xdg.cacheHome}/zsh"         # Shell completions
    mkdir -pm 755 "${config.xdg.cacheHome}/fontconfig"  # Font cache
  '';
}
