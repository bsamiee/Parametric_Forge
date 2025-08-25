# Title         : lib/font-patcher.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/font-patcher.nix
# ----------------------------------------------------------------------------
# Efficient font patching with smart caching.

{ nixpkgs }:

let
  inherit (nixpkgs) lib;
  build = import ./build.nix { inherit nixpkgs; };

  # --- Font Patching with Content-Addressed Caching ------------------------
  patchFont =
    pkgs: font:
    let
      # Create a stable hash based on font source
      fontHash = builtins.hashString "sha256" "${font.pname or font.name}-${font.version or "0"}";

      patchedFont = pkgs.stdenvNoCC.mkDerivation {
        pname = "${font.pname or font.name}-nerd";
        version = "${font.version or "0"}-${fontHash}";
        src = font;
        nativeBuildInputs = [ pkgs.nerd-font-patcher ];

        buildPhase = ''
          mkdir -p $out/share/fonts/truetype
          find $src -name "*.ttf" -o -name "*.otf" | while read f; do
            nerd-font-patcher "$f" --complete --mono --no-progressbars \
              --outputdir $out/share/fonts/truetype
          done
        '';

        installPhase = "true";
        meta = font.meta or { } // {
          description = "${font.pname or font.name} with Nerd Font icons";
          __contentAddressed = true;
        };
      };
    in
    # Apply content-based caching to prevent unnecessary rebuilds
    build.cached pkgs patchedFont [ font ];

  # --- Smart Filtering -------------------------------------------------------
  needsPatching =
    font:
    !(lib.any (k: lib.hasInfix k (toString font)) [
      "nerd-fonts"
      "nerd-font"
      "-nerd"
      "symbols"
      "icons"
      "emoji"
    ]);

in
{
  withIcons =
    pkgs: fonts:
    [ pkgs.nerd-fonts.symbols-only ] ++ map (f: if needsPatching f then patchFont pkgs f else f) (lib.unique fonts);
}
