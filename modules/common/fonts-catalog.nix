# Title         : fonts-catalog.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/fonts-catalog.nix
# ----------------------------------------------------------------------------
# Cross-scope font-package catalog: the single family-truth surface both the home owner (names, roles, projections, manifest) and the darwin owner
# (install list) fold. The attr name is the CoreText family; a family absent here is structurally uninstallable. `class`: static | variable | patched.
{pkgs}: let
  notoArabic = pkgs.noto-fonts.override {variants = ["NotoSansArabic" "NotoNaskhArabic"];};
  notoMono = pkgs.noto-fonts.override {variants = ["NotoSansMono"];};
in {
  "Geist Mono" = {
    package = pkgs.geist-font;
    file = "share/fonts/opentype/GeistMono-Regular.otf";
    class = "static";
    roles = ["mono"];
    lineHeight = 0.95;
  };
  Geist = {
    package = pkgs.geist-font;
    file = "share/fonts/opentype/Geist-Regular.otf";
    class = "static";
    roles = ["sans"];
  };
  Iosevka = {
    package = pkgs.iosevka-bin;
    file = "share/fonts/truetype/Iosevka-Regular.ttc";
    class = "static";
    roles = ["mono"];
    lineHeight = 1.0;
  };
  Hack = {
    package = pkgs.hack-font;
    file = "share/fonts/truetype/Hack-Regular.ttf";
    class = "static";
    roles = ["mono"];
    lineHeight = 1.0;
  };
  "IBM Plex Mono" = {
    package = pkgs.ibm-plex;
    file = "share/fonts/opentype/IBMPlexMono-Regular.otf";
    class = "static";
    roles = ["mono"];
    lineHeight = 1.05;
  };
  "Noto Sans Mono" = {
    package = notoMono;
    file = "share/fonts/noto/NotoSansMono.ttf";
    class = "variable";
    roles = ["mono"];
    lineHeight = 1.0;
  };
  "Symbols Nerd Font Mono" = {
    package = pkgs.nerd-fonts.symbols-only;
    file = "share/fonts/truetype/NerdFonts/Symbols/SymbolsNerdFontMono-Regular.ttf";
    class = "patched";
    roles = ["symbols"];
    sample = "\\uf07b \\ue0b0 \\ue712 \\uf121";
  };
  "Scheherazade New" = {
    package = pkgs.scheherazade-new;
    file = "share/fonts/truetype/ScheherazadeNew-Regular.ttf";
    class = "static";
    roles = ["script"];
    sample = "سلام دنیا چطوری";
  };
  "Noto Naskh Arabic" = {
    package = notoArabic;
    file = "share/fonts/noto/NotoNaskhArabic.ttf";
    class = "variable";
    roles = ["script"];
    sample = "سلام دنیا چطوری";
  };
  "Noto Sans Arabic" = {
    package = notoArabic;
    file = "share/fonts/noto/NotoSansArabic.ttf";
    class = "variable";
    roles = ["script"];
    sample = "سلام دنیا چطوری";
  };
}
