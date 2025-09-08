# Title         : 00.system/fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/fonts.nix
# ----------------------------------------------------------------------------
# System-wide font installation with automatic Nerd Font icon patching.

{ pkgs, myLib, ... }:

{
  # --- Font Packages --------------------------------------------------------
  fonts.packages = myLib.fonts.withIcons pkgs (
    with pkgs;
    [
      # --- Programming & Terminal Fonts -------------------------------------
      geist-font
      # Weights: Thin, UltraLight, Light, Regular, Medium, SemiBold, Bold, UltraBold, Black
      # Includes both Geist (sans) and Geist Mono variants

      iosevka
      # Weights: Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold, ExtraBold, Heavy
      # Highly customizable, narrow width, excellent for coding, default variant includes ligatures

      ibm-plex
      # Complete family with 4 subfamilies:
      # - IBM Plex Sans: Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold (with italics)
      # - IBM Plex Serif: Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold (with italics)
      # - IBM Plex Mono: Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold (with italics)
      # - IBM Plex Sans Condensed: Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold

      # --- UI & General Purpose Fonts ---------------------------------------
      inter
      # Weights: Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold, ExtraBold, Black (with italics)
      # Variable font with optical size axis, Optimized for UI, excellent readability at small sizes

      dm-sans
      # Weights: Regular, Medium, Bold (with italics)
      # Geometric sans-serif, low contrast, good for displays

      overpass
      # Weights: Thin, ExtraLight, Light, Regular, SemiBold, Bold, ExtraBold, Black (with italics)
      # Also includes Overpass Mono variant, Red Hat's font, inspired by Highway Gothic

      source-sans
      # Source Sans 3 - Weights: ExtraLight, Light, Regular, SemiBold, Bold, Black (with italics)
      # Variable font with weight axis (200-900)

      source-serif
      # Source Serif 4 - Weights: ExtraLight, Light, Regular, SemiBold, Bold, Black (with italics)
      # Transitional serif, pairs well with Source Sans
      # Variable font with weight and optical size axes

      # --- System & Fallback Fonts ------------------------------------------
      openmoji-color
      # OpenMoji color emoji font - 3,180+ emojis, outlined design style
      # CC BY-SA 4.0 license, more comprehensive than Noto Color Emoji

      noto-fonts
      # Noto Sans - Weights: Thin, ExtraLight, Light, Regular, Medium, SemiBold, Bold, ExtraBold, Black
      # Covers 100+ writing systems, excellent Unicode coverage
      # Also includes Noto Serif and Noto Sans Mono

      noto-fonts-extra
      # Additional Noto fonts including:
      # - Noto Nastaliq Urdu: Regular, Medium, SemiBold, Bold
      # - Many other regional scripts and variants

      # --- Arabic & Persian Fonts -------------------------------------------
      scheherazade-new
      # Weights: Regular, Medium, SemiBold, Bold
      # Traditional Arabic naskh style
      # Supports full Arabic Unicode range including Quranic text marks


      # --- Google Fonts Additions -------------------------------------------
      (google-fonts.override {
        fonts = [
          "Qahiri" # Arabic Kufic - Weights: Regular, Medium, Bold
          "ReemKufi" # Arabic geometric Kufic - Weights: Regular, with Ink and Fun variants
          "MarkaziText" # Arabic text font - Weights: Regular, Medium, SemiBold, Bold
          "PlayfairDisplay" # Display serif - Weights: Thin to Black (9 weights) with italics
        ];
      })
    ]
  );
}
