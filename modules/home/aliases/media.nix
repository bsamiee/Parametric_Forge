# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/aliases/media.nix
# ----------------------------------------------------------------------------
# Media register rows: playback, image, ffmpeg.
[
  {
    alias = "play";
    expansion = "mpv";
    desc = "Quick playback";
    category = "media";
  }
  {
    alias = "playl";
    expansion = "mpv --loop-file=inf";
    desc = "Loop current file";
    category = "media";
  }
  {
    alias = "plays";
    expansion = "mpv --shuffle";
    desc = "Shuffle playlist";
    category = "media";
  }
  {
    alias = "yt";
    expansion = "mpv --ytdl-format='bestvideo[height<=?1080]+bestaudio/best'";
    desc = "YouTube playback";
    category = "media";
  }
  {
    alias = "ascii";
    expansion = "ascii-image-converter";
    desc = "Image to ASCII art";
    category = "media";
  }
  {
    alias = "ffprobeh";
    expansion = "ffprobe -hide_banner";
    desc = "Clean media info";
    category = "media";
  }
  {
    alias = "ffplayh";
    expansion = "ffplay -hide_banner";
    desc = "Clean playback";
    category = "media";
  }
]
