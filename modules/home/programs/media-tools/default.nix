# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/default.nix
# ----------------------------------------------------------------------------
# Media tool inventory; imports carry real configuration only, and each imported file declares its own package. The table holds tools with
# no configuration.
{pkgs, ...}: let
  # nixpkgs builds the whole czkawka workspace, three GUI programs over gtk4 among it; the CLI crate alone links none of that.
  czkawkaCli = pkgs.czkawka.overrideAttrs {
    cargoBuildFlags = ["--package" "czkawka_cli"];
    buildInputs = [];
    postInstall = "";
    postFixup = "";
  };
in {
  imports = [
    ./models.nix
    ./svgo.nix
  ];

  home.packages = [
    pkgs.ab-av1 # CRF search to a VMAF target per video, over the profile's ffmpeg (libvmaf, SVT-AV1)
    czkawkaCli # czkawka_cli: similar images, videos, and music by perceptual hash; broken files, empty folders, big files
    pkgs.exiftool # Metadata read/write across image, video, PDF, and font containers
    pkgs.ffmpeg-full # Every codec, filter, and hwaccel nixpkgs offers on this platform; its whisper and arnndn filters load the models.nix files
    pkgs.ffmpeg-normalize # Two-pass EBU R128 loudnorm; the measure-then-apply JSON handoff is the one ffmpeg lane worth a wrapper
    pkgs.fonttools # fonttools, pyftsubset, ttx: subsetting that keeps layout features, TTX dump and patch, variable-font instancing, WOFF2
    pkgs.gallery-dl # Every image of a gallery or page at full resolution with metadata sidecars; yt-dlp is the video twin
    pkgs.gifski # GIF encoder reading video directly (nixpkgs builds the video feature); beats palettegen/paletteuse
    # nixpkgs row on purpose: the 16.x release tarball fails on Darwin three ways (no autogen.sh, plugin modules with unresolved libgvc symbols,
    # a bundled libltdl missing argz), and nothing in 16.x is load-bearing for dot; the pin returns when nixpkgs or upstream fixes the lane.
    pkgs.graphviz # dot layout family; ImageMagick's shipped `dot` delegate renders .dot sources through it
    # HarfBuzz builds its utilities by default (meson `utilities` is enabled) and seats them in the dev output. No hb-view: it is the one
    # utility that needs cairo, which harfbuzz-current disables, and pango-view covers that lane.
    pkgs.harfbuzz-current.dev # hb-shape, hb-subset, hb-info, hb-vector: shaping traces, font subsetting, face dumps, vector render
    pkgs.imagemagick
    pkgs.img2pdf # Images to PDF with the JPEG and PNG bytes embedded unchanged, at the page size their DPI states
    pkgs.jpegli # cjpegli, djpegli: JPEG encode and decode at higher quality per byte than libjpeg-turbo
    pkgs.mpv # Playback backend for media aliases
    # nixpkgs row on purpose: the next release line needs Pillow 13, pikepdf 10.18, pydantic 2.14, pypdfium2 5.15, and fpdf2 2.9, none of
    # which the pinned nixpkgs holds; the row moves with nixpkgs. Its recipe binds tesseract, ghostscript, unpaper, pngquant, and jbig2 by
    # store path, so the command needs none of them on PATH.
    pkgs.ocrmypdf # Searchable text layer on scanned PDFs: OCR, deskew, clean, PDF/A, and image optimization in one command
    pkgs.oxipng # Lossless PNG recompression for exported raster; no config or env surface
    pkgs.pandoc-current
    pkgs.pdfcpu # Booklet imposition, n-up, grid, stamps, watermarks, page boxes, form fill, and validation
    pkgs.poppler-utils
    pkgs.potrace # potrace, mkbitmap: black-and-white bitmap to vector outline
    pkgs.resvg # SVG to PNG renderer
    pkgs.ssimulacra2 # Perceptual image-difference score between an original and its compressed copy
    pkgs.typst
    pkgs.vl-convert # Vega and Vega-Lite specs to SVG/PNG/JPEG/PDF; V8 is linked in, so no Node and no browser
    pkgs.verapdf-current # Complete official CLI; the overlay owns its private current Java runtime.
    pkgs.yt-dlp # URL to media, subtitles, and --dump-json metadata; already inside mpv's wrapper closure, so the row costs nothing
  ];
}
