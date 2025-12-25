# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/media.nix
# ----------------------------------------------------------------------------
# Media and document processing environment variables
{
  config,
  pkgs,
  lib,
  ...
}: {
  home.sessionVariables = {
    # --- FFmpeg -------------------------------------------------------------
    FFREPORT = "file=${config.xdg.stateHome}/ffmpeg/%p-%t.log:level=32";
    AV_LOG_FORCE_COLOR = "1"; # Enable colored output

    # --- ImageMagick --------------------------------------------------------
    MAGICK_FONT_PATH = "/System/Library/Fonts:/Library/Fonts:${config.home.homeDirectory}/Library/Fonts:${config.home.profileDirectory}/share/fonts";
    MAGICK_CONFIGURE_PATH = lib.concatStringsSep ":" [
      "${config.xdg.configHome}/ImageMagick"
      "${pkgs.imagemagick}/etc/ImageMagick-7"
      "${pkgs.imagemagick}/share/ImageMagick-7"
    ];
    MAGICK_TEMPORARY_PATH = "${config.xdg.cacheHome}/ImageMagick";
    MAGICK_MEMORY_LIMIT = "2147483648";
    MAGICK_DISK_LIMIT = "2147483648";
    MAGICK_THREAD_LIMIT = "0";

    # --- Pandoc -------------------------------------------------------------
    PANDOC_DATA_DIR = "${config.xdg.dataHome}/pandoc";
  };
}
