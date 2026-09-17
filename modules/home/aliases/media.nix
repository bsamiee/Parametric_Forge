# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/media.nix
# ----------------------------------------------------------------------------
# Media register rows: playback, ffmpeg.
{
  media = [
    ["play" "mpv" "Quick playback"]
    ["playl" "mpv --loop-file=inf" "Loop current file"]
    ["plays" "mpv --shuffle" "Shuffle playlist"]
    ["yt" "mpv --ytdl-format='bestvideo[height<=?1080]+bestaudio/best'" "YouTube playback; mpv's wrapper carries yt-dlp"]
    ["ffprobeh" "ffprobe -hide_banner" "Clean media info"]
    ["ffplayh" "ffplay -hide_banner" "Clean playback"]
  ];
}
