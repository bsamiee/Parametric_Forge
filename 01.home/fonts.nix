# Title         : 01.home/fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/fonts.nix
# ----------------------------------------------------------------------------
# User fontconfig settings using system-installed fonts.

_:

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
}
