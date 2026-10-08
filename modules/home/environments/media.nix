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
  toolchainEnvFor,
  ...
}: let
  # FONTCONFIG_FILE and TYPST_FONT_PATHS are cross-surface rows of modules/common/toolchain-env.nix; the same font roots feed fonts.conf here.
  inherit
    (toolchainEnvFor {
      home = config.home.homeDirectory;
      username = config.home.username;
      xdgCacheHome = config.xdg.cacheHome;
    })
    fontDirectories
    ;
in {
  home.sessionVariables = {
    # --- [IMAGEMAGICK]
    # Freetype text (annotate/caption) resolves fonts through fontconfig, so no MAGICK_FONT_PATH row: ImageMagick reads that variable as one
    # directory, and a colon-joined list makes every named -font fail.
    MAGICK_CONFIGURE_PATH = lib.concatStringsSep ":" [
      "${config.xdg.configHome}/ImageMagick"
      "${pkgs.imagemagick-current}/etc/ImageMagick-7"
      "${pkgs.imagemagick-current}/share/ImageMagick-7"
    ];
    MAGICK_TEMPORARY_PATH = "${config.xdg.cacheHome}/ImageMagick";
    MAGICK_MEMORY_LIMIT = "2147483648";
    MAGICK_DISK_LIMIT = "2147483648";

    # --- [TYPST]
    # Typst resolves both package roots through the `dirs` crate, so macOS lands them under ~/Library/Caches and ~/Library/Application Support,
    # never XDG; the flags' env spellings are the only lever. pandoc needs no row: it reads XDG_DATA_HOME itself (xdg.nix keeps its data dir).
    TYPST_PACKAGE_CACHE_PATH = "${config.xdg.cacheHome}/typst/packages";
    TYPST_PACKAGE_PATH = "${config.xdg.dataHome}/typst/packages";

    # --- [FFMPEG]
    # ffpreset lookup is $FFMPEG_DATADIR, then $HOME/.ffmpeg, then the store datadir (ffmpeg(1), "Preset files"); the row moves the one writable
    # leg off the dotfile path. FFREPORT stays unset: any value turns every invocation into a debug log dump in the working directory.
    FFMPEG_DATADIR = "${config.xdg.dataHome}/ffmpeg";
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
