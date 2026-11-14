# Title         : yt-dlp.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/yt-dlp.nix
# ----------------------------------------------------------------------------
# URL to media, subtitles, and --dump-json metadata, signed in through Safari. YouTube answers an anonymous client with HTTP 429 on captions
# and 403 on media once a session has pulled a few dozen videos; requests carrying the browser's cookies pass, so every run reads them.
_: {
  programs.yt-dlp = {
    enable = true;
    settings.cookies-from-browser = "safari";
  };
}
