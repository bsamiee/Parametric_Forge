# Title         : ffmpeg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/ffmpeg.nix
# ----------------------------------------------------------------------------
# FFmpeg ecosystem for media processing and thumbnail generation
{pkgs, ...}: let
  ffmpegForge = pkgs.ffmpeg-full.override {
    # nixpkgs lcevcdec 4.2.0 currently fails to link on Darwin; keep FFmpeg otherwise full.
    withLcevcdec = false;
  };
in {
  home.packages = [
    ffmpegForge
    pkgs.ffmpegthumbnailer # Lightweight video thumbnailer for Yazi preview (ffmpegthumbnailer.yazi)
  ];
}
