# Title         : 01.home/fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/fonts.nix
# ----------------------------------------------------------------------------
# User fontconfig settings using system-installed fonts.

{ lib, pkgs, ... }:

let
  # --- Precise Nerd Font fallback mapping (fontconfig) ----------------------
  # Note: macOS apps use CoreText and ignore fontconfig; this is for Linux/GTK/Qt
  # The prefer list is used for glyph fallback when the primary family lacks a glyph
  fontAliases = {
    # Monospace families with real NF names
    "Geist Mono" = [
      "GeistMono Nerd Font"
      "Symbols Nerd Font Mono"
    ];
    "Iosevka" = [
      "Iosevka Nerd Font"
      "Symbols Nerd Font Mono"
    ];
    "IBM Plex Mono" = [
      "BlexMono Nerd Font"
      "Symbols Nerd Font Mono"
    ];
    "Overpass" = [
      "Overpass Nerd Font Mono"
      "Overpass Nerd Font"
      "Symbols Nerd Font Mono"
    ];

    # UI/Sans families (no NF variant) → prefer Symbols NF for icons fallback
    "Geist" = [ "Symbols Nerd Font" ];
    "Inter" = [ "Symbols Nerd Font" ];
    "DM Sans" = [ "Symbols Nerd Font" ];
    "IBM Plex Sans" = [ "Symbols Nerd Font" ];
    "IBM Plex Serif" = [ "Symbols Nerd Font" ];
    "Source Sans 3" = [ "Symbols Nerd Font" ];
    "Source Serif 4" = [ "Symbols Nerd Font" ];
  };

  mkAliasBlock = name: preferList: ''
    <alias>
      <family>${name}</family>
      <prefer>
        ${lib.concatStrings (map (f: "<family>" + f + "</family>") preferList)}
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

  # --- Linux-only fontconfig aliases (CoreText ignores these on macOS) ------
  xdg.configFile."fontconfig/conf.d/99-nerd-font-aliases.conf" = lib.mkIf pkgs.stdenv.isLinux {
    text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        ${lib.concatStrings (lib.mapAttrsToList mkAliasBlock fontAliases)}
      </fontconfig>
    '';
  };

  # --- Ensure fontconfig loads conf.d (needed if FONTCONFIG_FILE is set) ----
  xdg.configFile."fontconfig/fonts.conf" = {
    text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <include ignore_missing="yes">conf.d</include>
      </fontconfig>
    '';
  };
}
