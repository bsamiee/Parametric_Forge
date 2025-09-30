# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/default.nix
# ----------------------------------------------------------------------------
# Media tools aggregator

{ lib, ... }:

{
  imports = [
    ./ffmpeg.nix            # FFmpeg + thumbnailer for Yazi
    ./imagemagick.nix
    ./mpv.nix
    ./yt-dlp.nix            # High-quality video downloader defaults
    ./resvg.nix             # Yazi: SVG preview rendering
    ./poppler.nix           # Yazi: PDF preview utilities
    ./djvulibre.nix         # Yazi: DjVu document support
    ./mediainfo.nix         # Yazi: Enhanced media info preview
    ./exiftool.nix          # Yazi: Audio metadata preview
    ./chafa.nix             # Yazi: Fallback image preview
    ./glow.nix              # Yazi: Markdown preview
    ./inkscape.nix          # Vector graphics editor
    ./transmission.nix      # Transmission BitTorrent client (CLI/daemon)

    # Document processing
    ./pandoc.nix            # Universal document converter
    ./ocrmypdf.nix          # OCR text layer for scanned PDFs
    ./qpdf.nix              # Structural PDF utility
  ];
}
