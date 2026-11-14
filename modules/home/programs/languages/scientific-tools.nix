{
  lib,
  pkgs,
  ...
}: let
  qpdfCompletion = pkgs.runCommand "qpdf-zsh-completion" {} ''
    mkdir -p "$out/share/zsh/site-functions"
    ${lib.getExe pkgs.qpdf} --completion-zsh > "$out/share/zsh/site-functions/_qpdf"
  '';

  artifactTools = with pkgs; [
    file
    fontconfig
    gdal
    ghostscript
    libjpeg_turbo
    librsvg-current
    mupdf-current
    pango
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
