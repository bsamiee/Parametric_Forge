# Title         : yt-dlp.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/yt-dlp.nix
# ----------------------------------------------------------------------------
# yt-dlp configuration for high-quality downloads

{ config, lib, pkgs, ... }:

let
  outputPath = lib.escapeShellArg "${config.home.homeDirectory}/Downloads/%(uploader)s/%(title)s.%(ext)s";
  archivePath = lib.escapeShellArg "${config.home.homeDirectory}/Downloads/.yt-dlp-archive.txt";

  configText = ''
    --output ${outputPath}
    --format bestvideo[height<=1080]+bestaudio/best[height<=1080]
    --format-sort res:1080,fps,codec:h264:m4a,size,br,asr
    --extract-audio
    --audio-format mp3
    --audio-quality 0
    --write-info-json
    --write-description
    --write-thumbnail
    --embed-thumbnail
    --add-metadata
    --write-subs
    --sub-langs en,en-US
    --download-archive ${archivePath}
    --continue
    --no-overwrites
    --retries 3
    --fragment-retries 3
    --limit-rate 1M
    --user-agent "Mozilla/5.0 (compatible; yt-dlp)"
    --no-playlist
  '';
in
{
  home.packages = [ pkgs.yt-dlp ];

  xdg.configFile."yt-dlp/config" = {
    text = configText;
    executable = false;
  };
}
