# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/media.nix
# ----------------------------------------------------------------------------
# Media and document processing environment variables
{
  config,
  host,
  pkgs,
  lib,
  ...
}: let
  fontDirectories =
    lib.optionals (host.os == "darwin") [
      "/System/Library/Fonts"
      "/Library/Fonts"
      "${config.home.homeDirectory}/Library/Fonts"
      # The operator-owned design font store, one recursive root: fontconfig <dir> and Typst both descend it.
      "${config.home.homeDirectory}/Library/Application Support/design-tools/fonts"
    ]
    # Darwin package fonts already live under ~/Library/Fonts/HomeManager (Home Manager's native target), so the profile row is Linux-only.
    ++ lib.optional (host.os != "darwin") "${config.home.profileDirectory}/share/fonts";
in {
  home.sessionVariables = {
    # --- [IMAGEMAGICK]
    # Freetype text (annotate/caption) resolves fonts through fontconfig, not MAGICK_FONT_PATH — the generated
    # config below indexes the same Darwin + generation dirs, so both resolution paths agree.
    FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    # System font dirs are a Darwin fact; the profile share is portable.
    MAGICK_FONT_PATH = lib.concatStringsSep ":" fontDirectories;
    TYPST_FONT_PATHS = lib.concatStringsSep ":" fontDirectories;
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

  # The XML generator orders children by element name (cachedir, dir, include), so the base include lands after the estate dirs; fontconfig
  # unions directories regardless of order, and precedence is by match score, so the generated order is inert.
  # Home Manager rsyncs the font payload with preserved store mtimes (epoch 1), so fontconfig's mtime-keyed directory cache never notices a
  # generation swap on its own; the forced rescan after the file phase keeps the Pango/ImageMagick lane current with every switch.
  home.activation.fontconfigCache = lib.mkIf (host.os == "darwin") (lib.hm.dag.entryAfter ["onFilesChange"] ''
    [ ! -d "$HOME/Library/Fonts/HomeManager" ] || run env FONTCONFIG_FILE=${config.xdg.configHome}/fontconfig/fonts.conf ${pkgs.fontconfig}/bin/fc-cache -f "$HOME/Library/Fonts/HomeManager"
  '');

  xdg.configFile."fontconfig/fonts.conf".source = (pkgs.formats.xml {}).generate "fonts.conf" {
    fontconfig = {
      include = {
        "@ignore_missing" = "yes";
        "#text" = "${pkgs.fontconfig.out}/etc/fonts/fonts.conf";
      };
      dir = fontDirectories;
      cachedir = "${config.xdg.cacheHome}/fontconfig";
    };
  };
}
