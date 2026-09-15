# Title         : scientific-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/scientific-tools.nix
# ----------------------------------------------------------------------------
# Machine-wide native command-line tools and runtimes. The per-user profile links bin and man alone (nix-darwin environment.pathsToLink), so a
# row here lands commands only: a source build reaches each library through the scientificSessionEnv rows of modules/common/toolchain-env.nix,
# each a store reference, and a ctypes consumer through the forge-runtime-dylibs tree the same file exports. A package landing no command has no
# consumer here.
{
  lib,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # KTX-Software builds portably under plain CMake; nixpkgs still caps meta.platforms at linux, so the lift is
  # the entire darwin admission. Carries the ktx/ktx2check/toktx CLIs.
  ktxTools = pkgs.ktx-tools.overrideAttrs (prev: {
    meta = prev.meta // {platforms = lib.platforms.unix;};
  });

  geoTools = with pkgs; [
    gdal # gdalinfo, gdal_translate, ogr2ogr, and the gdal-config the GDAL_CONFIG row names
    geos # geosop and the geos-config the GEOS_CONFIG row names
    proj # proj, cs2cs, projinfo
    netcdf # ncdump, nccopy, ncgen
  ];

  columnarTools = [pkgs.arrow-cpp]; # parquet-reader, parquet-scan, parquet-dump-*; pyarrow reaches the library through the CMAKE_PREFIX_PATH row

  artifactTools = with pkgs; [
    file # file; python-magic dlopens libmagic off the runtime dylib tree
    fontconfig # fc-list, fc-match, fc-cache; weasyprint dlopens libfontconfig off the runtime dylib tree
    fribidi
    gdk-pixbuf
    ghostscript
    glib # gio, gsettings, gdbus; weasyprint and pyvips (ABI mode) dlopen libgobject and libglib off the runtime dylib tree
    ktxTools # KTX2 encode seam: the ktx/ktx2check/toktx CLIs spawned by the Rasm C# and python branches; TS consumes the produced bytes
    lcms2
    leptonica
    libheif # heif-enc, heif-dec, heif-info; pi-heif reaches the library through the PKG_CONFIG_PATH row
    libjpeg_turbo
    libtiff
    libwebp
    mupdf
    openjpeg
    pango # pango-view; weasyprint dlopens libpango off the runtime dylib tree
    qpdf
    tesseract
    vips # vips, vipsthumbnail; pyvips (ABI mode) dlopens libvips off the runtime dylib tree
  ];

  # EnergyPlus/OpenStudio bind macOS only; gmsh is a project row (the PyPI wheel carries the CLI), never a machine package.
  aecTools = lib.optionals isDarwin [
    pkgs.energyplus
    pkgs.openstudio
  ];
in {
  home.packages =
    [
      pkgs.pkg-config # pyicu (icu-config, then pkg-config), h5py, and pi-heif resolve their libraries through it at build time
    ]
    ++ geoTools
    ++ columnarTools
    ++ artifactTools
    ++ aecTools;
}
