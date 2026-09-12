# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/default.nix
# ----------------------------------------------------------------------------
# Media tool inventory; imports carry real configuration only.
{pkgs, ...}: let
  # nixpkgs lcevcdec fails to link on Darwin, and frei0r-plugins pulls libdrm (linux-only); keep FFmpeg otherwise full.
  ffmpegForge = pkgs.ffmpeg-full.override {
    withLcevcdec = false;
    withFrei0r = false;
  };
  # Cairo/raster belong to the complete CLI variant; enabling them on the core HarfBuzz attr creates the Cairo/Pango dependency cycle. Only bin/
  # reaches the profile — the dev output also carries headers and pkg-config files. The shaping oracle stays on base harfbuzz (home/fonts.nix).
  harfbuzzTools = let
    hb = pkgs.harfbuzz.override {
      withCairo = true;
      withRaster = true;
    };
  in
    pkgs.runCommand "harfbuzz-tools-${hb.version}" {inherit (hb) meta;} ''
      mkdir -p $out/bin
      ln -st $out/bin ${hb.dev}/bin/hb-*
      [ -e $out/bin/hb-view ] || { echo "harfbuzz drift: hb-view missing from the cairo build" >&2; exit 1; }
    '';
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
    harfbuzzTools # hb-view/hb-raster plus the base tools; the manifest oracle stays on base harfbuzz
    pkgs.inkscape
    pkgs.mediainfo # Media container inspection for Yazi preview
    pkgs.mpv # Playback backend for media aliases
    pkgs.pandoc-current
    pkgs.poppler-utils-current # Current PDF utilities; app dependencies keep nixpkgs' compatible Poppler library.
    pkgs.resvg # SVG rendering for Yazi preview
    pkgs.typst
    pkgs.vega-cli
    pkgs.verapdf-current # Complete official CLI; the overlay owns its private current Java runtime.
  ];
}
