# Title         : scientific-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/scientific-tools.nix
# ----------------------------------------------------------------------------
# Machine-wide native command-line tools and runtimes. The per-user profile links bin and man alone (nix-darwin environment.pathsToLink), so a
# row here lands commands only; a project's Pixi environment owns the native libraries its builds link. A package landing no command has no
# consumer here.
{
  lib,
  pkgs,
  ...
}: let
  # KTX-Software builds portably under plain CMake; nixpkgs still caps meta.platforms at linux, so the lift is
  # the entire darwin admission. Carries the ktx/ktx2check/toktx CLIs.
  ktxTools = pkgs.ktx-tools.overrideAttrs (prev: {
    meta = prev.meta // {platforms = lib.platforms.unix;};
  });

  geoTools = with pkgs; [
    gdal # gdalinfo, gdal_translate, ogr2ogr
    geos # geosop
    proj # proj, cs2cs, projinfo
    netcdf # ncdump, nccopy, ncgen
  ];

  # qpdf ships no completion file and emits a `#compdef qpdf` drop-in on demand; one runCommand seats it on the profile's site-functions,
  # which zsh/completions.nix already has on fpath ahead of compinit.
  qpdfCompletion = pkgs.runCommand "qpdf-zsh-completion" {} ''
    mkdir -p "$out/share/zsh/site-functions"
    ${lib.getExe pkgs.qpdf-current} --completion-zsh > "$out/share/zsh/site-functions/_qpdf"
  '';

  columnarTools = [pkgs.arrow-cpp]; # parquet-reader, parquet-scan, parquet-dump-*

  artifactTools = with pkgs; [
    file # file
    fontconfig # fc-list, fc-match, fc-cache
    ghostscript
    ktxTools # KTX2 encode seam: the ktx/ktx2check/toktx CLIs a consumer spawns to encode textures
    lcms2
    libheif # heif-enc, heif-dec, heif-info
    libjpeg_turbo
    libtiff
    libwebp
    mupdf
    openjpeg
    pango # pango-view
    qpdf-current
    qpdfCompletion
    tesseract
    vips # vips, vipsthumbnail
  ];

  # gmsh is a project row (the PyPI wheel carries the CLI), never a machine package.
  aecTools = [
    pkgs.energyplus
    pkgs.openstudio
  ];
in {
  home.packages = geoTools ++ columnarTools ++ artifactTools ++ aecTools;
}
