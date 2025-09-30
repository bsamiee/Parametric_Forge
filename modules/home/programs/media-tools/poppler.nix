# Title         : poppler.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/poppler.nix
# ----------------------------------------------------------------------------
# PDF utilities (pdfinfo, pdftotext) required by Yazi for PDF preview

{ pkgs, ... }:

{
  home.packages = [ pkgs.poppler_utils ];
}
