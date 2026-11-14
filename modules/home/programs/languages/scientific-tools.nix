# Title         : scientific-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/scientific-tools.nix
# ----------------------------------------------------------------------------
# Machine-wide native command-line tools and runtimes. nix-darwin environment.pathsToLink links no lib or include, so a row here lands
# commands, man pages, and completions alone. A package landing no command has no consumer here.
{
  lib,
  pkgs,
  ...
}: let
  # gdalinfo, gdal_translate, ogr2ogr. `gdal-config` prints compiler and linker flags for gdal's store headers and libraries, and a source
  # build finding it on PATH links them, so the row drops it. The Nix PROJ data ships no datum grids; each command streams them from
  # cdn.proj.org into the user PROJ directory, and the wrapper scopes the switch to these commands, so a project's PROJ consumers keep their
  # own data and network policy.
  gdalCommands = pkgs.symlinkJoin {
    inherit (pkgs.gdal) pname version;
    paths = [pkgs.gdal];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      rm "$out/bin/gdal-config"
      for command in "$out"/bin/*; do
        wrapProgram "$command" --set-default PROJ_NETWORK ON
      done
    '';
  };

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
    libjpeg_turbo # cjpeg, djpeg, jpegtran
    librsvg-current # rsvg-convert
    mupdf
    pango # pango-view
    qpdf
    qpdfCompletion
    tesseract
    vips # vips, vipsthumbnail
  ];

  aecTools = [
    pkgs.energyplus
    pkgs.openstudio
  ];
in {
  home.packages = [gdalCommands] ++ artifactTools ++ aecTools;
}
