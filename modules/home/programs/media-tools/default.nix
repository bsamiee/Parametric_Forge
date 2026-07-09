# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/media-tools/default.nix
# ----------------------------------------------------------------------------
# Media tool inventory; imports carry real configuration only.
{pkgs, ...}: let
  # nixpkgs lcevcdec 4.2.0 currently fails to link on Darwin; keep FFmpeg otherwise full.
  ffmpegForge = pkgs.ffmpeg-full.override {withLcevcdec = false;};
in {
  imports = [
    ./glow.nix
  ];

  home.packages = [
    pkgs.ascii-image-converter # Raster images to ASCII art
    pkgs.chafa # Terminal graphics fallback for Yazi image preview
    pkgs.djvulibre # DjVu document support for djvu-view.yazi
    pkgs.exiftool # Media metadata read/write for Yazi audio preview
    ffmpegForge # Full-featured FFmpeg for media processing and conversion
    pkgs.ffmpegthumbnailer # Lightweight video thumbnailer for Yazi preview (ffmpegthumbnailer.yazi)
    pkgs.glow # Terminal markdown rendering; config owned by glow.nix
    pkgs.imagemagick # ImageMagick 7 image manipulation suite
    pkgs.inkscape # Vector graphics editor and CLI
    pkgs.mediainfo # Media container inspection for Yazi preview
    pkgs.mpv # Playback backend for media aliases
    pkgs.pandoc # Universal document converter
    pkgs.poppler-utils # PDF utilities (pdfinfo, pdftotext) for Yazi preview
    pkgs.qpdf # Structural, encryption, and linearization PDF operations
    pkgs.resvg # SVG rendering for Yazi preview
  ];
}
