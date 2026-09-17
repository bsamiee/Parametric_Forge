# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/default.nix
# ----------------------------------------------------------------------------
# Media tool inventory; imports carry real configuration only.
{pkgs, ...}: let
  # HarfBuzz's command-line shaper. nixpkgs passes no `utilities` meson option, so the library package's bin output (outputBin = "dev") ships
  # empty; the utilities build lands hb-shape, hb-subset, and hb-info. No cairo: hb-view (specimen raster) is the one utility that needs it, and
  # pango-view covers that lane; the build rides its own derivation so no libharfbuzz consumer re-keys.
  harfbuzzTools = pkgs.harfbuzz.overrideAttrs (prev: {
    mesonFlags = prev.mesonFlags ++ [(pkgs.lib.mesonEnable "utilities" true)];
  });
in {
  # Yazi's documented dependency set (ffmpeg video thumbnails, poppler PDF, resvg SVG, ImageMagick raster, Chafa as the adapter of last resort
  # inside the Zellij popup) resolves by bare name on PATH; the rows below are those tools.
  home.packages = [
    pkgs.chafa # Yazi image adapter where no graphics protocol passes through; also the one terminal image/ASCII renderer
    pkgs.exiftool # Metadata read/write across image, video, PDF, and font containers
    pkgs.ffmpeg-full # Every codec, filter, and hwaccel nixpkgs offers on this platform, whisper transcription included; frei0r and opencv build locally
    pkgs.ffmpeg-normalize # Two-pass EBU R128 loudnorm; the measure-then-apply JSON handoff is the one ffmpeg lane worth a wrapper
    pkgs.gifski # GIF encoder reading video directly (nixpkgs builds the video feature); beats palettegen/paletteuse
    # nixpkgs row on purpose: the 16.x release tarball fails on Darwin three ways (no autogen.sh, plugin modules with unresolved libgvc symbols,
    # a bundled libltdl missing argz), and nothing in 16.x is load-bearing for dot; the pin returns when nixpkgs or upstream fixes the lane.
    pkgs.graphviz # dot layout family; ImageMagick's shipped `dot` delegate renders .dot sources through it
    harfbuzzTools.dev # hb-shape, hb-subset, hb-info: shaping traces and font subsetting; harfbuzz seats its utilities in the dev output
    pkgs.imagemagick
    pkgs.mediainfo # Yazi `inspect` opener row
    pkgs.mpv # Playback backend for media aliases
    pkgs.oxipng # Lossless PNG recompression for exported raster; no config or env surface
    pkgs.pandoc-current
    pkgs.poppler-utils-current # Current PDF utilities; app dependencies keep nixpkgs' compatible Poppler library.
    pkgs.resvg # SVG rendering for Yazi preview and the mermaid validator
    pkgs.typst
    pkgs.vl-convert # Vega and Vega-Lite specs to SVG/PNG/JPEG/PDF; V8 is linked in, so no Node and no browser
    pkgs.verapdf-current # Complete official CLI; the overlay owns its private current Java runtime.
    pkgs.whisper-cpp # GGML model fetcher and VAD segmenter for ffmpeg's built-in whisper filter, which ships no model of its own
    pkgs.yt-dlp # URL to media, subtitles, and --dump-json metadata; already inside mpv's wrapper closure, so the row costs nothing
  ];
}
