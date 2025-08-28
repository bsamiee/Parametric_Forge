# Title         : 00.system/darwin/applications.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/applications.nix
# ----------------------------------------------------------------------------
# Custom macOS applications unavailable in Homebrew - system-wide installation.

{ pkgs, lib, ... }:

let
  # --- Local Installation Function ------------------------------------------
  installMacApp = 
    { name
    , version
    , src
    , appname ? name
    , sourceRoot ? "${appname}.app"
    , description ? ""
    , homepage ? ""
    , postInstall ? ""
    , ...
    }:
    pkgs.stdenv.mkDerivation {
      name = "${name}-${version}";
      inherit version src sourceRoot;
      
      buildInputs = [ pkgs.undmg pkgs.unzip ];
      phases = [ "unpackPhase" "installPhase" ];
      
      installPhase = ''
        mkdir -p "$out/Applications"
        cp -pR . "$out/Applications/${sourceRoot}"
        ${postInstall}
      '';
      
      meta = with lib; {
        inherit description homepage;
        platforms = platforms.darwin;
      };
    };
in
{
  # --- System-Wide GUI Applications -----------------------------------------
  environment.systemPackages = [
    # Adobe Plugin Managers (unavailable in Homebrew)
    (installMacApp {
      name = "aescripts-aeplugins";
      appname = "aescripts + aeplugins";
      version = "latest";
      src = pkgs.fetchurl {
        url = "https://updates.aescripts.com/updater/mac/aescripts%20+%20aeplugins%20manager%20(setup).dmg";
        sha256 = "sha256-zJJ9qpkxYzLnYVwzCjjU8W8brFXNEeehU0txpYpdAVc=";
      };
      description = "Plugin manager for After Effects scripts and plugins";
      homepage = "https://aescripts.com/";
    })

    (installMacApp {
      name = "AstuteManager";
      appname = "Astute Manager";
      version = "latest";
      src = pkgs.fetchurl {
        url = "https://files.astutegraphics.com/AstuteManager.dmg";
        sha256 = "sha256-mmJSze6sgkdRuwsdYNVsicuxnO1pC9FFt8XE968Oz4o=";
      };
      description = "Plugin manager for Astute Graphics Illustrator plugins";
      homepage = "https://astutegraphics.com/";
    })
  ];
}