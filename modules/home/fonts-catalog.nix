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
  geist = selectPaths pkgs.geist-font-current (map (name: "share/fonts/truetype/${name}[wght].ttf") ["Geist" "Geist-Italic" "GeistMono" "GeistMono-Italic"]);
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
in {
  "Geist Mono" = {
    package = geist;
    lineHeight = 0.95;
  };
  Geist.package = geist;
  "Symbols Nerd Font Mono" = {
    package = selectPaths pkgs.nerd-fonts.symbols-only ["share/fonts/truetype/NerdFonts/Symbols/SymbolsNerdFontMono-Regular.ttf"];
    inherit statusAlphabet;
  };
  "Scheherazade New".package = pkgs.scheherazade-new-current;
  "Noto Naskh Arabic".package = notoArabic;
  "Noto Sans Arabic".package = notoArabic;
}
