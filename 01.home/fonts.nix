# Title         : 01.home/fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/fonts.nix
# ----------------------------------------------------------------------------
# User fontconfig settings using system-installed fonts.

{ lib, pkgs, ... }:

let
  # --- Font Names That Get Patched ------------------------------------------
  patchedFonts = [
    "Geist"
    "Geist Mono"
    "Inter"
    "DM Sans"
    "IBM Plex Sans"
    "IBM Plex Serif"
    "IBM Plex Mono"
    "Source Sans 3"
    "Source Serif 4"
    "Overpass"
    "Iosevka"
  ];

  # --- Generate Font Aliases ------------------------------------------------
  mkFontAlias = fontName: ''
    <alias>
      <family>${fontName}</family>
      <prefer>
        <family>${fontName} Nerd Font</family>
      </prefer>
    </alias>
  '';
in
{
  # --- Fontconfig Settings --------------------------------------------------
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      # --- Serif Fonts (Document/Reading) -----------------------------------
      serif = [
        "Source Serif 4" # Primary serif - Variable font with optical size
        "IBM Plex Serif" # Secondary serif - Professional, clean
        "Noto Serif" # Fallback serif - Comprehensive Unicode coverage
      ];

      # --- Sans-Serif Fonts (UI/Interface) ----------------------------------
      sansSerif = [
        "Geist" # Primary sans - Modern, clean design
        "Inter" # UI optimized - Excellent small-size readability
        "DM Sans" # Geometric sans - Low contrast, display-friendly
        "IBM Plex Sans" # Professional sans - IBM's corporate font
        "Source Sans 3" # Adobe's sans - UI-friendly, variable font
        "Overpass" # Red Hat's sans - Highway Gothic inspired
        "Noto Sans" # Ultimate fallback - 100+ writing systems
      ];

      # --- Monospace Fonts (Programming/Terminal) ---------------------------
      monospace = [
        "Geist Mono" # Primary mono - Clean, readable coding font
        "Iosevka" # Highly configurable - Narrow, ligature support
        "IBM Plex Mono" # Professional mono - IBM's coding font
        "Noto Sans Mono" # Fallback mono - Unicode coverage
      ];

      # --- Emoji Fonts ------------------------------------------------------
      emoji = [ "OpenMoji" ]; # Open source, outlined style, 3,180+ emojis
    };

  };

  # --- Darwin-Only Font Aliases via XDG File --------------------------------
  # Redirect original font requests to Nerd Font variants
  xdg.configFile."fontconfig/conf.d/99-nerd-font-aliases.conf" = lib.mkIf pkgs.stdenv.isDarwin {
    text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        ${lib.concatStrings (map mkFontAlias patchedFonts)}
      </fontconfig>
    '';
  };
}
