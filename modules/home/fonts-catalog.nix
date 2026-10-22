# Title         : fonts-catalog.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/fonts-catalog.nix
# ----------------------------------------------------------------------------
# Font-package catalog for Home Manager installation and renderer roles. The attr name is the CoreText family.
{pkgs}: let
  inherit (pkgs) lib;
  selectPaths = package: paths:
    (pkgs.linkFarm "${package.pname}-${package.version}" (lib.genAttrs paths (path: "${package}/${path}"))).overrideAttrs (old: {
      inherit (package) meta;
      buildCommand =
        old.buildCommand
        + ''
          for path in ${lib.escapeShellArgs paths}; do
            [[ -e "$out/$path" ]] || { echo "${package.pname}: selected font path missing: $path" >&2; exit 1; }
          done
        '';
    });
  notoArabic = pkgs.noto-fonts.override {variants = ["NotoSansArabic" "NotoNaskhArabic"];};
  geist = selectPaths pkgs.geist-font (map (name: "share/fonts/truetype/${name}[wght].ttf") ["Geist" "Geist-Italic" "GeistMono" "GeistMono-Italic"]);
  # Closed two-register alphabets for terminal-bound render surfaces, owned beside the symbols family the theme owner mints glyphs from — one
  # row per class, no by-value mirror anywhere. Status rows: [role codepoint asciiTwin].
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
    lineHeight = 0.95;
  };
  Geist.package = geist;
  "Symbols Nerd Font Mono" = {
    package = pkgs.nerd-fonts.symbols-only;
    inherit statusAlphabet gitAlphabet;
  };
  "Scheherazade New".package = pkgs.scheherazade-new;
  "Noto Naskh Arabic".package = notoArabic;
  "Noto Sans Arabic".package = notoArabic;
}
