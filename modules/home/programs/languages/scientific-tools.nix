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
  # The Nix PROJ data ships no datum grids; each gdal and proj command streams them from cdn.proj.org into the user PROJ directory. The
  # wrapper scopes the switch to these commands, so a project's PROJ consumers keep their own data and network policy.
  projNetwork = package:
    pkgs.symlinkJoin {
      name = "${package.pname}-proj-network-${package.version}";
      paths = [package];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        for command in "$out"/bin/*; do
          wrapProgram "$command" --set-default PROJ_NETWORK ON
        done
      '';
    };
  geoTools = with pkgs; [
    (projNetwork gdal) # gdalinfo, gdal_translate, ogr2ogr
    geos # geosop
    (projNetwork proj) # proj, cs2cs, projinfo
    netcdf # ncdump, nccopy, ncgen
  ];

  # qpdf ships no completion file and emits a `#compdef qpdf` drop-in on demand; one runCommand seats it on the profile's site-functions,
  # which zsh/completions.nix already has on fpath ahead of compinit.
  qpdfCompletion = pkgs.runCommand "qpdf-zsh-completion" {} ''
    mkdir -p "$out/share/zsh/site-functions"
    ${lib.getExe pkgs.qpdf} --completion-zsh > "$out/share/zsh/site-functions/_qpdf"
  '';

  artifactTools = with pkgs; [
    file # file
    fontconfig # fc-list, fc-match, fc-cache
    ghostscript
    ktx-tools # KTX2 encode seam: the ktx/ktx2check/toktx CLIs a consumer spawns to encode textures
    lcms2
    libheif # heif-enc, heif-dec, heif-info
    libjpeg_turbo
    librsvg-current # rsvg-convert
    libtiff
    libwebp
    mupdf
    openjpeg
    pango # pango-view
    qpdf
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
  home.packages = geoTools ++ artifactTools ++ aecTools;
}
