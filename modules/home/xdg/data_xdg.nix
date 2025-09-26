# Title         : data_xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg/data_xdg.nix
# ----------------------------------------------------------------------------
# XDG_DATA_HOME directory structure

{ config, lib, ... }:

{
  home.activation.createDataDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Data directories for installed tools and resources

    # --- System Resources ---------------------------------------------------
    mkdir -pm 755 "${config.xdg.dataHome}/fonts"        # Custom fonts
    mkdir -pm 755 "${config.xdg.dataHome}/nix-defexpr"  # Nix expressions

    # --- Language Related ---------------------------------------------------

  '';
}
