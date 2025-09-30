# Title         : ocrmypdf.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/ocrmypdf.nix
# ----------------------------------------------------------------------------
# OCRmyPDF - add an OCR text layer to scanned PDFs

{ pkgs, ... }:

{
  home.packages = [ pkgs.ocrmypdf ];
}
