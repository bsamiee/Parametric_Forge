# Title         : config_xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg/config_xdg.nix
# ----------------------------------------------------------------------------
# XDG_CONFIG_HOME directory structure

{ config, lib, ... }:

{
  home.activation.createConfigDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''

    # --- Shell System -------------------------------------------------------
    mkdir -pm 755 "${config.xdg.configHome}/nix"
    mkdir -pm 755 "${config.xdg.configHome}/git"
    mkdir -pm 755 "${config.xdg.configHome}/zsh"
    mkdir -pm 755 "${config.xdg.configHome}/bat/syntaxes"
    mkdir -pm 755 "${config.xdg.configHome}/bat/themes"

    # --- Container Related --------------------------------------------------


    # --- Languages Related --------------------------------------------------


    # --- Media Related ------------------------------------------------------


    # --- Application Related ------------------------------------------------

  '';
}
