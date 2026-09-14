# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/default.nix
# ----------------------------------------------------------------------------
# Media tool inventory; imports carry real configuration only.
{pkgs, ...}: let
  # HarfBuzz's command-line shapers. nixpkgs passes no `utilities` meson option and disables the cairo backend, so the library package's bin
  # output (outputBin = "dev") ships empty; hb-view renders through cairo, so both land here. They ride their own build of the same source
  # rather than the overlay's row, because every consumer that links libharfbuzz would otherwise carry cairo in its closure.
  harfbuzzTools = (pkgs.harfbuzz.override {withCairo = true;}).overrideAttrs (prev: {
    mesonFlags = prev.mesonFlags ++ [(pkgs.lib.mesonEnable "utilities" true)];
  });
  # nixpkgs lcevcdec fails to link on Darwin, and frei0r-plugins pulls libdrm (linux-only); keep FFmpeg otherwise full.
  ffmpegForge = pkgs.ffmpeg-full.override {
    withLcevcdec = false;
    withFrei0r = false;
  };
in {
  imports = [
    ./glow.nix
  ];

  # Yazi's documented dependency set (ffmpeg video thumbnails, poppler PDF, resvg SVG, ImageMagick raster, Chafa as the adapter of last resort
  # inside the Zellij popup) resolves by bare name on PATH; the rows below are those tools.
  home.packages = [
    pkgs.ascii-image-converter
    pkgs.chafa # Yazi image adapter where no graphics protocol passes through
    pkgs.exiftool # Metadata read/write across image, video, PDF, and font containers
    ffmpegForge
    pkgs.glow # Config owned by glow.nix
    harfbuzzTools.dev # hb-shape and hb-view: shaping traces and specimen rendering; harfbuzz seats its utilities in the dev output
    pkgs.imagemagick
    pkgs.mediainfo # Yazi `inspect` opener row
    pkgs.mpv # Playback backend for media aliases
    pkgs.pandoc-current
    pkgs.poppler-utils-current # Current PDF utilities; app dependencies keep nixpkgs' compatible Poppler library.
    pkgs.resvg # SVG rendering for Yazi preview and the mermaid validator
    pkgs.typst
    pkgs.vega-cli
    pkgs.verapdf-current # Complete official CLI; the overlay owns its private current Java runtime.
  ];
}
