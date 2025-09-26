# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/media.nix
# ----------------------------------------------------------------------------
# Media and document processing environment variables

{ config, pkgs, ... }:

{
  home.sessionVariables = {
    # --- FFmpeg --------------------------------------------------------------
    FFREPORT = "file=${config.xdg.stateHome}/ffmpeg/ffreport.log:level=32";

    # --- ImageMagick ---------------------------------------------------------
    MAGICK_FONT_PATH = "/System/Library/Fonts:/Library/Fonts:${config.home.homeDirectory}/Library/Fonts:${config.home.profileDirectory}/share/fonts";
    MAGICK_CONFIGURE_PATH = "${config.xdg.configHome}/ImageMagick";
    MAGICK_TEMPORARY_PATH = "${config.xdg.cacheHome}/ImageMagick";
    MAGICK_MEMORY_LIMIT = "2GB";
    MAGICK_DISK_LIMIT = "2GB";
    MAGICK_THREAD_LIMIT = "0";

    # --- Document Processing -------------------------------------------------
    PANDOC_DATA_DIR = "${config.xdg.dataHome}/pandoc";
    D2_LAYOUT = "dagre";

    # --- Fontconfig ----------------------------------------------------------
    FONTCONFIG_PATH = "${config.xdg.configHome}/fontconfig";
    FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    FONTCONFIG_CACHE = "${config.xdg.cacheHome}/fontconfig";
  };
}
