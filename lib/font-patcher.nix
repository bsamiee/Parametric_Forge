# Title         : lib/font-patcher.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/font-patcher.nix
# ----------------------------------------------------------------------------
# Smart font management: Use pre-patched Nerd Fonts from nixpkgs.

{ nixpkgs }:

let
  inherit (nixpkgs) lib;

in
{
  # --- Main Export: Font List with Icons ------------------------------------
  # Strategy: Use pre-patched fonts from nixpkgs nerd-fonts collection
  # This avoids the complexity and build time of patching fonts ourselves
  withIcons =
    pkgs: fonts:
    let
      # Always include symbols-only for fallback glyphs
      basePackages = [ pkgs.nerd-fonts.symbols-only ];

      # Map regular fonts to their nerd-fonts equivalents
      # This uses the actual pre-patched fonts from nixpkgs
      getNerdFont =
        font:
        let
          fontName = font.pname or font.name or "";

          # Comprehensive mapping of regular fonts to nerd-fonts packages
          # Based on actual packages available in pkgs.nerd-fonts.*
          nerdFontMapping = {
            # Fonts with direct nerd-fonts equivalents
            "iosevka" = pkgs.nerd-fonts.iosevka;
            "iosevka-bin" = pkgs.nerd-fonts.iosevka;
            "jetbrains-mono" = pkgs.nerd-fonts.jetbrains-mono;
            "fira-code" = pkgs.nerd-fonts.fira-code;
            "fira-mono" = pkgs.nerd-fonts.fira-mono;
            "hack" = pkgs.nerd-fonts.hack;
            "hack-font" = pkgs.nerd-fonts.hack;
            "liberation" = pkgs.nerd-fonts.liberation;
            "liberation_ttf" = pkgs.nerd-fonts.liberation;
            "noto" = pkgs.nerd-fonts.noto;
            "noto-fonts" = pkgs.nerd-fonts.noto;
            "ubuntu" = pkgs.nerd-fonts.ubuntu;
            "ubuntu_font_family" = pkgs.nerd-fonts.ubuntu;
            "ubuntu-mono" = pkgs.nerd-fonts.ubuntu-mono;
            "roboto-mono" = pkgs.nerd-fonts.roboto-mono;
            "space-mono" = pkgs.nerd-fonts.space-mono;
            "victor-mono" = pkgs.nerd-fonts.victor-mono;
            "cascadia-code" = pkgs.nerd-fonts.caskaydia-cove;
            "dejavu-fonts" = pkgs.nerd-fonts.dejavu-sans-mono;
            "inconsolata" = pkgs.nerd-fonts.inconsolata;
            "meslo-lgs-nf" = pkgs.nerd-fonts.meslo-lg;
            "meslo-lg" = pkgs.nerd-fonts.meslo-lg;
            "go-font" = pkgs.nerd-fonts.go-mono;
            "droid-sans-mono" = pkgs.nerd-fonts.droid-sans-mono;
            "terminus-font" = pkgs.nerd-fonts.terminess-ttf;

            # Name transformations (nixpkgs uses different names)
            "ibm-plex" = pkgs.nerd-fonts.blex-mono; # IBM Plex Mono
            "source-code-pro" = pkgs.nerd-fonts.sauce-code-pro;
            "overpass" = pkgs.nerd-fonts.overpass;
            "geist-font" = pkgs.nerd-fonts.geist-mono;

            # Fonts that need the originals (no nerd-fonts variant)
            "inter" = font; # Use original + symbols-only fallback
            "dm-sans" = font; # Use original
            "source-sans" = font; # Use original
            "source-serif" = font; # Use original
            "source-sans-pro" = font; # Use original
            "source-serif-pro" = font; # Use original

            # Emoji and symbol fonts - never patch these
            "openmoji-color" = font;
            "openmoji-black" = font;
            "noto-fonts-emoji" = font;
            "noto-fonts-color-emoji" = font;
            "emojione" = font;
            "twemoji-color-font" = font;

            # Arabic/special fonts - use originals
            "scheherazade-new" = font;
            "amiri" = font;
            "noto-fonts-extra" = font;
          };
        in
        nerdFontMapping.${fontName} or font; # Default to original if not mapped

      # Process the font list
      processedFonts = map getNerdFont (lib.unique fonts);

      # Filter out duplicates between base and processed
      finalFonts = lib.unique (basePackages ++ processedFonts);
    in
    finalFonts;
}
