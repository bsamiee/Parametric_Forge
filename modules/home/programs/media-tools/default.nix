# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/default.nix
# ----------------------------------------------------------------------------
# Media tools aggregator
{pkgs, ...}: {
  imports = [
    ./ffmpeg.nix # FFmpeg + thumbnailer for Yazi
    ./imagemagick.nix
    ./resvg.nix # Yazi: SVG preview rendering
    ./poppler.nix # Yazi: PDF preview utilities
    ./djvulibre.nix # Yazi: DjVu document support
    ./mediainfo.nix # Yazi: Enhanced media info preview
    ./exiftool.nix # Yazi: Audio metadata preview
    ./chafa.nix # Yazi: Fallback image preview
    ./ascii-image-converter.nix # Convert images to ASCII art
    ./glow.nix # Yazi: Markdown preview
    ./inkscape.nix # Vector graphics editor

    # Document processing
    ./pandoc.nix # Universal document converter
    ./qpdf.nix # Structural PDF utility
  ];

  home.packages = [
    pkgs.mpv # Playback backend for media aliases
  ];
}
