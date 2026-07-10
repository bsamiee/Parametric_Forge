# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/default.nix
# ----------------------------------------------------------------------------
# Media tool inventory; imports carry real configuration only.

{pkgs, ...}: let
  # nixpkgs lcevcdec fails to link on Darwin; keep FFmpeg otherwise full.
  ffmpegForge = pkgs.ffmpeg-full.override {withLcevcdec = false;};
in {
  imports = [
    ./glow.nix
  ];

  home.packages = [
    pkgs.ascii-image-converter
    pkgs.chafa # Terminal graphics fallback for Yazi image preview
    pkgs.djvulibre # DjVu document support for djvu-view.yazi
    pkgs.exiftool # Media metadata read/write for Yazi audio preview
    ffmpegForge
    pkgs.ffmpegthumbnailer # Lightweight video thumbnailer for Yazi preview (ffmpegthumbnailer.yazi)
    pkgs.glow # Config owned by glow.nix
    pkgs.imagemagick
    pkgs.inkscape
    pkgs.mediainfo # Media container inspection for Yazi preview
    pkgs.mpv # Playback backend for media aliases
    pkgs.pandoc
    pkgs.poppler-utils # PDF utilities (pdfinfo, pdftotext) for Yazi preview
    pkgs.qpdf
    pkgs.resvg # SVG rendering for Yazi preview
  ];
}
