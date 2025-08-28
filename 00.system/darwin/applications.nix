# Title         : 00.system/darwin/applications.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/applications.nix
# ----------------------------------------------------------------------------
# Custom macOS applications unavailable in Homebrew - system-wide installation.

{ pkgs, lib, ... }:

let
  # --- App Existence Check Function -----------------------------------------
  appExists = appPath: builtins.pathExists appPath;

  # --- Local Installation Function ------------------------------------------
  installMacApp =
    {
      name,
      version,
      src,
      appname ? name,
      sourceRoot ? "${appname}.app",
      description ? "",
      homepage ? "",
      postInstall ? "",
      ...
    }:
    pkgs.stdenv.mkDerivation {
      name = "${name}-${version}";
      inherit version src sourceRoot;

      buildInputs = [
        pkgs.undmg
        pkgs.unzip
      ];
      phases = [
        "unpackPhase"
        "installPhase"
      ];

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
  environment.systemPackages =
    lib.optionals (!appExists "/Applications/aescripts + aeplugins.app") [
      # Adobe Plugin Managers (unavailable in Homebrew) - Only if not present
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
    ]
    ++ lib.optionals (!appExists "/Applications/Astute Manager.app") [
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
    ]
    ++ lib.optionals (!appExists "/Applications/Supercharge.app") [
      (installMacApp {
        name = "supercharge";
        appname = "Supercharge";
        version = "1.19.0";
        src = pkgs.fetchurl {
          url = "https://www.dropbox.com/scl/fi/p4gknv4nho0gfdrxsjsmk/Supercharge-1.19.0-trial-1753461750.zip?rlkey=sksbnms59el6o2bnvm4iv1ftl&dl=1";
          name = "Supercharge-1.19.0.zip"; # Clean filename for unpacker
          sha256 = "sha256-p7Kh7wOYUkbzUImu2UzTZU4PXci9Zi+HtlcdM4YfM7E=";
        };
        description = "Elevate your Mac experience with useful functionality";
        homepage = "https://sindresorhus.com/supercharge";
      })
    ];
}
