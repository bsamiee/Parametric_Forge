# Title         : ffmpeg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/ffmpeg.nix
# ----------------------------------------------------------------------------
# FFmpeg ecosystem for media processing and thumbnail generation
{pkgs, ...}: {
  home.packages = with pkgs; [
    ffmpeg-full # Full-featured FFmpeg with maximum codec support
    ffmpegthumbnailer # Lightweight video thumbnailer for Yazi preview (ffmpegthumbnailer.yazi)
  ];
}
