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

  # qpdf ships no completion file and emits a `#compdef qpdf` drop-in on demand; one runCommand seats it on the profile's site-functions,
  # which zsh/completions.nix already has on fpath ahead of compinit.
  qpdfCompletion = pkgs.runCommand "qpdf-zsh-completion" {} ''
    mkdir -p "$out/share/zsh/site-functions"
    ${lib.getExe pkgs.qpdf} --completion-zsh > "$out/share/zsh/site-functions/_qpdf"
  '';

  columnarTools = [pkgs.arrow-cpp]; # parquet-reader, parquet-scan, parquet-dump-*; pyarrow reaches the library through the CMAKE_PREFIX_PATH row

  artifactTools = with pkgs; [
    file # file; python-magic dlopens libmagic off the runtime dylib tree
    fontconfig # fc-list, fc-match, fc-cache; weasyprint dlopens libfontconfig off the runtime dylib tree
    ghostscript
    ktxTools # KTX2 encode seam: the ktx/ktx2check/toktx CLIs spawned by the Rasm C# and python branches; TS consumes the produced bytes
    lcms2
    libheif # heif-enc, heif-dec, heif-info; pi-heif reaches the library through the PKG_CONFIG_PATH row
    libjpeg_turbo
    libtiff
    libwebp
    mupdf
    openjpeg
    pango # pango-view; weasyprint dlopens libpango off the runtime dylib tree
    qpdf
    qpdfCompletion
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
