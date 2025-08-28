# Title         : media-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/media-tools.nix
# ----------------------------------------------------------------------------
# Media processing and manipulation tools.

{ pkgs, ... }:

with pkgs;
[
  # --- Media Processing -----------------------------------------------------
  ffmpeg # Complete multimedia framework for audio/video
  imagemagick # Image manipulation and conversion
  vips # High-performance image processing (4-5x faster than ImageMagick)
  handbrake # CLI video transcoder (GUI version in homebrew.nix)

  # --- Document Processing --------------------------------------------------
  pandoc # Universal document converter (markdown, docx, pdf, etc.)
  # pandoc → Also managed by programs.pandoc in media-tools.nix (programs dir)
  poppler_utils # PDF utilities (pdfinfo, pdftotext) - Required by yazi for PDF preview
  djvulibre # DjVu document support - Required by djvu-view.yazi

  # --- Media Analysis -------------------------------------------------------
  mediainfo # Detailed media file information - Enhanced yazi preview
  exiftool # Read/write metadata in media files - Audio preview metadata
  hexyl # hexdump/xxd → Colorful hex viewer for binary analysis
  ffmpegthumbnailer # Faster video thumbnail generation - Required by ffmpegthumbnailer.yazi

  # --- Visualization & Diagrams ---------------------------------------------
  graphviz # Graph visualization software (DOT language)
  d2 # Modern diagram scripting language
  resvg # SVG rasterizer - Required by yazi for SVG preview

  # --- Document Rendering ---------------------------------------------------
  glow # Render markdown in terminal - Beautiful markdown preview
  mdcat # Cat for markdown with syntax highlighting
]
