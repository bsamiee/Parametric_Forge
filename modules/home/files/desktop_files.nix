# Title         : desktop_files.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/files/desktop_files.nix
# ----------------------------------------------------------------------------
# Linux desktop entries for GUI applications, only deployed on Linux systems (macOS uses .app bundles)

{ lib, pkgs, ... }:

{
  xdg.dataFile = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
    # --- Desktop Entries ----------------------------------------------------
    # Format: "applications/name.desktop"

    # Example structure:
    # "applications/code.desktop".text = ''
    #   [Desktop Entry]
    #   Type=Application
    #   Name=Visual Studio Code
    #   Exec=code %F
    #   Icon=code
    #   MimeType=text/plain;
    #   Categories=Development;TextEditor;
    # '';
  };
}
