# Title         : fonts-catalog.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/fonts-catalog.nix
# ----------------------------------------------------------------------------
# Font-package catalog for Home Manager installation and renderer roles. The attr name is the CoreText family; `class`: static | variable | patched.
{pkgs}: let
  inherit (pkgs) lib;
  selectPaths = package: paths:
    (pkgs.linkFarm "${package.pname}-${package.version}" (lib.genAttrs paths (path: "${package}/${path}"))).overrideAttrs (old: {
      inherit (package) pname version meta;
      buildCommand =
        old.buildCommand
        + ''
          for path in ${lib.escapeShellArgs paths}; do
            [[ -e "$out/$path" ]] || { echo "${package.pname}: selected font path missing: $path" >&2; exit 1; }
          done
        '';
    });
  notoArabic = pkgs.noto-fonts.override {variants = ["NotoSansArabic" "NotoNaskhArabic"];};
  notoMono = pkgs.noto-fonts.override {variants = ["NotoSansMono"];};
  geist = selectPaths pkgs.geist-font (map (name: "share/fonts/truetype/${name}[wght].ttf") ["Geist" "Geist-Italic" "GeistMono" "GeistMono-Italic"]);
  # Typeface owns Google's newer Sans variable family. OTFs retain the distinct language/Condensed/Math coverage; selected variable TTFs omit
  # duplicated static faces and upstream AppleDouble files without altering the original packages.
  plex = selectPaths (pkgs.ibm-plex.override {
    families = ["math" "mono-variable" "serif-variable" "sans-condensed" "sans-arabic" "sans-devanagari" "sans-hebrew" "sans-jp" "sans-kr" "sans-sc" "sans-tc" "sans-thai" "sans-thai-looped"];
  }) (["share/fonts/opentype"] ++ lib.concatMap (family: map (style: "share/fonts/truetype/IBM Plex ${family} Var-${style}.ttf") ["Roman" "Italic"]) ["Mono" "Serif"]);
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
  # Git-state vocabulary rows: [state rolePath codepoint asciiTwin] — the codicon diff_* family; the dotted role path resolves on the theme
  # owner's folded families (the contextBadges grammar), so each row names its hue unambiguously and a new state is one row, never a map edit.
  # typechange shares the modified glyph (a mode flip is a modify) and clean shares the staged check; both stay rows so consumers dispatch by state.
  gitAlphabet = [
    ["added" "state.success" "eadc" "[+]"]
    ["staged" "state.success" "eab2" "[*]"]
    ["modified" "state.info" "eade" "[~]"]
    ["deleted" "state.danger" "eadf" "[-]"]
    ["untracked" "state.success" "eb32" "[?]"]
    ["renamed" "accent.structural" "eae0" "[>]"]
    ["typechange" "state.info" "eade" "[~]"]
    ["conflict" "accent.secondary" "ea6c" "[!]"]
    ["ahead" "state.success" "eaa1" "[^]"]
    ["behind" "state.warning" "ea9a" "[v]"]
    ["diverged" "state.attention" "ea99" "[%]"]
    ["stashed" "text.muted" "ea98" "[$]"]
    ["clean" "state.success" "eab2" "[=]"]
  ];
in {
  "Geist Mono" = {
    package = geist;
    file = "share/fonts/truetype/GeistMono[wght].ttf";
    class = "variable";
    roles = ["mono"];
    lineHeight = 0.95;
  };
  Geist = {
    package = geist;
    file = "share/fonts/truetype/Geist[wght].ttf";
    class = "variable";
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
  "IBM Plex Mono Var" = {
    package = plex;
    file = "share/fonts/truetype/IBM Plex Mono Var-Roman.ttf";
    class = "variable";
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
