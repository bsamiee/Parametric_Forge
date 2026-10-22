# Title         : media.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/media.nix
# ----------------------------------------------------------------------------
# Media register rows: playback, ffmpeg.
{
  media = [
    ["play" "mpv"]
    ["playl" "mpv --loop-file=inf"]
    ["plays" "mpv --shuffle"]
    ["yt" "mpv --ytdl-format='bestvideo[height<=?1080]+bestaudio/best'"]
    ["ffprobeh" "ffprobe -hide_banner"]
    ["ffplayh" "ffplay -hide_banner"]
  ];
}
