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
    # --- [FFMPEG]
    FFREPORT = "file=${config.xdg.stateHome}/ffmpeg/%p-%t.log:level=32";

    # --- [IMAGEMAGICK]
    # Freetype text (annotate/caption) resolves fonts through fontconfig, not MAGICK_FONT_PATH — the generated
    # config below indexes the same Darwin + profile dirs, so both resolution paths agree.
    FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    # System font dirs are a Darwin fact; the profile share is portable.
    MAGICK_FONT_PATH = lib.concatStringsSep ":" (lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        "/System/Library/Fonts"
        "/Library/Fonts"
        "${config.home.homeDirectory}/Library/Fonts"
      ]
      ++ ["${config.home.profileDirectory}/share/fonts"]);
    MAGICK_CONFIGURE_PATH = lib.concatStringsSep ":" [
      "${config.xdg.configHome}/ImageMagick"
      "${pkgs.imagemagick}/etc/ImageMagick-7"
      "${pkgs.imagemagick}/share/ImageMagick-7"
    ];
    MAGICK_TEMPORARY_PATH = "${config.xdg.cacheHome}/ImageMagick";
    MAGICK_MEMORY_LIMIT = "2147483648";
    MAGICK_DISK_LIMIT = "2147483648";
    MAGICK_THREAD_LIMIT = "0";

    # --- [PANDOC]
    PANDOC_DATA_DIR = "${config.xdg.dataHome}/pandoc";
  };

  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <include ignore_missing="yes">${pkgs.fontconfig.out}/etc/fonts/fonts.conf</include>
      <dir>/System/Library/Fonts</dir>
      <dir>/Library/Fonts</dir>
      <dir>${config.home.homeDirectory}/Library/Fonts</dir>
      <dir>${config.home.profileDirectory}/share/fonts</dir>
      <cachedir>${config.xdg.cacheHome}/fontconfig</cachedir>
    </fontconfig>
  '';
}
