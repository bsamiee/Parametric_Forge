{
  lib,
  pkgs,
  ...
}: let
  qpdfCompletion = pkgs.runCommand "qpdf-zsh-completion" {} ''
    mkdir -p "$out/share/zsh/site-functions"
    ${lib.getExe pkgs.qpdf} --completion-zsh > "$out/share/zsh/site-functions/_qpdf"
  '';

  pangoView = pkgs.symlinkJoin {
    inherit (pkgs.pango) pname version;
    paths = [pkgs.pango.bin];
    meta.mainProgram = "pango-view";
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''wrapProgram "$out/bin/pango-view" --set-default PANGOCAIRO_BACKEND fc'';
  };

  artifactTools = with pkgs; [
    file
    fontconfig
    gdal
    ghostscript
    libjpeg_turbo
    librsvg-current
    mupdf-current
    pangoView
    pdal
    qpdf
    qpdfCompletion
    tesseract
    vips
  ];

  aecTools = [
    pkgs.energyplus
    pkgs.openstudio
  ];
in {
  home.packages = artifactTools ++ aecTools;
}
