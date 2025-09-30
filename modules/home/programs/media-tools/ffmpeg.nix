# Title         : ffmpeg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/ffmpeg.nix
# ----------------------------------------------------------------------------
# FFmpeg ecosystem for media processing and thumbnail generation

{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Full-featured FFmpeg with maximum codec support
    ffmpeg-full

    # Lightweight video thumbnailer for Yazi preview (ffmpegthumbnailer.yazi)
    ffmpegthumbnailer
  ];
}
