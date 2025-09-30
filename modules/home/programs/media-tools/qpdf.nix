# Title         : qpdf.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/media-tools/qpdf.nix
# ----------------------------------------------------------------------------
# QPDF - structural, encryption, and linearization operations for PDFs

{ pkgs, ... }:

{
  home.packages = [ pkgs.qpdf ];
}
