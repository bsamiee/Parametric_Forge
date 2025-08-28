# Title         : sketchybar.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/01.packages/sketchybar.nix
# ----------------------------------------------------------------------------
# SketchyBar system stats provider (only unavailable component).

{
  lib,
  pkgs,
  context,
  ...
}:

lib.optionals context.isDarwin [
  # Only custom build what's not available in official sources
  # - sketchybar: Available via Homebrew (FelixKratz/formulae)
  # - sbarlua: Available in nixpkgs
  # - app-font: Available via Homebrew cask
  (pkgs.rustPlatform.buildRustPackage rec {
    pname = "sketchybar-system-stats";
    version = "0.6.4";

    src = pkgs.fetchFromGitHub {
      owner = "joncrangle";
      repo = "sketchybar-system-stats";
      rev = version;
      sha256 = "sha256-HExdDDIgYF/DGOYmAT41iOkM+7L9TDxxMd/MWFhwlCM=";
    };

    cargoHash = "sha256-vRvfoHaz8BNIyXj1u69a9yr3fxgqz3TuquwoeMPpRwU=";

    meta = with lib; {
      description = "System statistics provider for SketchyBar";
      homepage = "https://github.com/joncrangle/sketchybar-system-stats";
      license = licenses.gpl3Only;
      platforms = platforms.darwin;
    };
  })
  # Include SbarLua from nixpkgs (already available)
  pkgs.sbarlua
]
