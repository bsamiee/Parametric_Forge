# Title         : data_files.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/files/data_files.nix
# ----------------------------------------------------------------------------
# XDG data directory deployments

{ lib, pkgs, ... }:

{
  xdg.dataFile = {
    # --- Application Data ---------------------------------------------------
    # pandoc templates, themes, etc.

    # --- Tool Data ----------------------------------------------------------
    # completion files, man pages, etc.

    # --- Custom Schemas -----------------------------------------------------
    # XML schemas, JSON schemas, etc.
  };
}
