# Title         : ui-daemon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/services/ui-daemon.nix
# ----------------------------------------------------------------------------
# UI services using built-in nix-darwin service modules.

{ pkgs, lib, context, ... }:

let
  # Custom system stats provider (not available in nixpkgs)
  sketchybar-system-stats = pkgs.rustPlatform.buildRustPackage rec {
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
  };
in
{
  # --- SketchyBar Status Bar ------------------------------------------------
  services.sketchybar = {
    enable = lib.mkDefault context.isDarwin;
    package = pkgs.sketchybar;
    extraPackages = [
      pkgs.sbarlua                    # Lua interface for SketchyBar
      pkgs.sketchybar-app-font        # App icon font
      sketchybar-system-stats         # Custom system stats provider
    ];
    # Configuration managed via ~/.config/sketchybar/sketchybarrc (deployed by home-manager)
  };
}