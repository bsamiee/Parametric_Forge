# Title         : media-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/media-tools.nix
# ----------------------------------------------------------------------------
# Media processing and manipulation tools.

{ lib, context, ... }:

{
  programs = {
    # --- Pandoc Configuration ----------------------------------------------
    pandoc = {
      enable = true;
      # Note: Templates and filters are managed in data directories
    };

    # --- yt-dlp Configuration ---------------------------------------------
    yt-dlp = {
      enable = true;
      settings = {
        # --- Output Configuration -------------------------------------------
        output = "~/Downloads/%(uploader)s/%(title)s.%(ext)s";

        # --- Quality Selection ------------------------------------------
        format = "bestvideo[height<=1080]+bestaudio/best[height<=1080]";
        format-sort = "res:1080,fps,codec:h264:m4a,size,br,asr";

        # --- Audio Extraction -------------------------------------------
        extract-flat = false;
        audio-format = "mp3";
        audio-quality = "0"; # Best quality

        # --- Metadata and Thumbnails ------------------------------------
        write-info-json = true;
        write-description = true;
        write-thumbnail = true;
        write-all-thumbnails = false;
        embed-thumbnail = true;
        add-metadata = true;

        # --- Subtitles -------------------------------------------------
        write-subs = true;
        write-auto-subs = false;
        sub-langs = "en,en-US";

        # --- Archive and Resume ----------------------------------------
        download-archive = "~/Downloads/.yt-dlp-archive.txt";
        continue = true;
        no-overwrites = true;

        # --- Network and Rate Limiting ----------------------------------
        retries = "3";
        fragment-retries = "3";
        limit-rate = "1M";

        # --- User Agent and Headers -------------------------------------
        user-agent = "Mozilla/5.0 (compatible; yt-dlp)";

        # --- Playlist Handling ------------------------------------------
        yes-playlist = false; # Don't download entire playlists by default

        # --- Platform-specific Configuration ---------------------------
      } // lib.optionalAttrs context.isDarwin {
        # macOS-specific settings
        output = "~/Downloads/%(uploader)s/%(title)s.%(ext)s";
      } // lib.optionalAttrs (!context.isDarwin) {
        # Linux-specific settings
        output = "~/Downloads/%(uploader)s/%(title)s.%(ext)s";
      };
    };
  };
}