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
  # Closed two-register alphabets for terminal-bound render surfaces, owned here so the symbols family's shaping sample derives from the same
  # columns the theme owner mints glyphs from — one row per class, no by-value mirror anywhere. Status rows: [role codepoint asciiTwin].
  statusAlphabet = [
    ["running" "ea71" "[>]"]
    ["idle" "eabc" "[ ]"]
    ["attention" "eb32" "[?]"]
    ["failure" "ea87" "[X]"]
    ["ok" "eab2" "[OK]"]
    ["bell" "eaa2" "[B]"]
    ["warning" "ea6c" "[!]"]
    ["sync" "ea77" "[~]"]
  ];
  # Git-state vocabulary rows: [state colorRole codepoint asciiTwin] — the codicon diff_* family, colors resolved on the theme state ladder.
  # typechange shares the modified glyph (a mode flip is a modify) and clean shares the staged check; both stay rows so consumers dispatch by state.
  gitAlphabet = [
    ["added" "success" "eadc" "[+]"]
    ["staged" "success" "eab2" "[*]"]
    ["modified" "info" "eade" "[~]"]
    ["deleted" "danger" "eadf" "[-]"]
    ["untracked" "success" "eb32" "[?]"]
    ["renamed" "structural" "eae0" "[>]"]
    ["typechange" "info" "eade" "[~]"]
    ["conflict" "secondary" "ea6c" "[!]"]
    ["ahead" "success" "eaa1" "[^]"]
    ["behind" "warning" "ea9a" "[v]"]
    ["diverged" "attention" "ea99" "[%]"]
    ["stashed" "muted" "ea98" "[$]"]
    ["clean" "success" "eab2" "[=]"]
  ];
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
    inherit statusAlphabet gitAlphabet;
    # Proof corpus: powerline/dev glyphs, the container badge (oct-container), and both alphabets' codepoints — the hb-shape zero-.notdef gate
    # proves every width-load-bearing glyph the estate renders, not a token sample.
    sample = builtins.concatStringsSep " " (["\\uf07b" "\\ue0b0" "\\ue712" "\\uf121" "\\uf4b7"]
      ++ map (t: "\\u" + builtins.elemAt t 1) statusAlphabet
      ++ map (t: "\\u" + builtins.elemAt t 2) gitAlphabet);
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
