# Title         : fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/fonts.nix
# ----------------------------------------------------------------------------
# System font configuration using native Nix packages

{ lib, pkgs, ... }:

{
  fonts = {
    # nix-darwin uses fonts.packages directly, no fontDir needed
    packages = with pkgs; [
      # --- Programming/Terminal fonts ----------------------------------------
      nerd-fonts.geist-mono
      nerd-fonts.hack
      nerd-fonts.iosevka
      nerd-fonts.symbols-only

      # Monospace fonts
      ibm-plex              # IBM Plex family (includes Mono)
      (noto-fonts.override {
        variants = [ "NotoSansMono" ];
      })

      # --- UI/System fonts ---------------------------------------------------
      geist-font            # Geist Sans (UI font)
      inter                 # Inter (UI font)
      dm-sans               # DM Sans
      overpass              # Overpass
      source-sans           # Source Sans 3
      source-serif          # Source Serif 4

      # --- Arabic/Persian fonts ----------------------------------------------
      (noto-fonts.override {
        variants = [ "NotoSansArabic" "NotoNaskhArabic" ];
      })
      scheherazade-new      # Arabic script font
    ];
  };
}
