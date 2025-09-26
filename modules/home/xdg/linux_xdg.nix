# Title         : linux_xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg/linux_xdg.nix
# ----------------------------------------------------------------------------
# Linux-specific XDG user directories

{ config, lib, pkgs, ... }:

{
  xdg.userDirs = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    createDirectories = true;

    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    desktop = "${config.home.homeDirectory}/Desktop";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
  };

  # --- Linux desktop integration directories --------------------------------
  home.activation.createLinuxDirs = lib.hm.dag.entryAfter ["writeBoundary"] (
    lib.optionalString pkgs.stdenv.isLinux ''
      # --- Desktop integration ----------------------------------------------
      mkdir -pm 755 "${config.xdg.dataHome}/applications"
      mkdir -pm 755 "${config.xdg.dataHome}/icons"

      # --- FreeDesktop.org Trash specification ------------------------------
      mkdir -pm 755 "${config.xdg.dataHome}/Trash"
      mkdir -pm 755 "${config.xdg.dataHome}/Trash/files"
      mkdir -pm 755 "${config.xdg.dataHome}/Trash/info"
    ''
  );
}
