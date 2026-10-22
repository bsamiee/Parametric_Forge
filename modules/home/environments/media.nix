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
    # directory, and a colon-joined list makes every named -font fail. Configuration needs no row either: ImageMagick searches
    # $XDG_CONFIG_HOME/ImageMagick and its compiled-in etc and share directories by default.
    MAGICK_TEMPORARY_PATH = "${config.xdg.cacheHome}/ImageMagick";
    MAGICK_MEMORY_LIMIT = "2147483648";
    MAGICK_DISK_LIMIT = "2147483648";

    # --- [TYPST]
    # Typst resolves both package roots through the `dirs` crate, so macOS lands them under ~/Library/Caches and ~/Library/Application Support,
    # never XDG; the flags' env spellings are the only lever. pandoc needs no row: it reads XDG_DATA_HOME itself.
    TYPST_PACKAGE_CACHE_PATH = "${config.xdg.cacheHome}/typst/packages";
    TYPST_PACKAGE_PATH = "${config.xdg.dataHome}/typst/packages";

    # --- [FFMPEG]
    # ffpreset lookup is $FFMPEG_DATADIR, then $HOME/.ffmpeg, then the store datadir (ffmpeg(1), "Preset files"); the row moves the one writable
    # leg off the dotfile path. FFREPORT stays unset: any value turns every invocation into a debug log dump in the working directory.
    FFMPEG_DATADIR = "${config.xdg.dataHome}/ffmpeg";
  };

  # Root fontconfig file (FONTCONFIG_FILE): the store fonts.conf includes only /etc/fonts/conf.d, absent on macOS, so the stock conf.d chain is
  # included by store path; its 50-user.conf loads ~/.config/fontconfig/conf.d, where Home Manager writes the profile font dirs (with their
  # store-built cache) and the default families. The Home Manager font copies under ~/Library/Fonts keep store-epoch mtimes that fontconfig's
  # directory cache never sees change, so they are rejected and the store profile serves those faces. The XML generator orders children by
  # element name; fontconfig unions directories regardless of order, and precedence is by match score, so the generated order is inert.
  xdg.configFile."fontconfig/fonts.conf".source = (pkgs.formats.xml {}).generate "fonts.conf" {
    fontconfig = {
      include =
        map (path: {
          "@ignore_missing" = "yes";
          "#text" = path;
        }) [
          "${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
          "${pkgs.fontconfig.out}/etc/fonts/conf.d"
        ];
      dir = fontDirectories;
      cachedir = "${config.xdg.cacheHome}/fontconfig";
      selectfont.rejectfont.glob = "${config.home.homeDirectory}/Library/Fonts/HomeManager/*";
    };
  };
}
