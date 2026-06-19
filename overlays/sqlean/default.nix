# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/sqlean/default.nix
# ----------------------------------------------------------------------------
# SQLean - bundled SQLite extension libraries (https://github.com/nalgeon/sqlean)
{
  lib,
  stdenv,
  fetchzip,
}: let
  version = "0.28.3";
  system = stdenv.hostPlatform.system;

  platformAsset =
    if system == "aarch64-darwin"
    then {
      url = "https://github.com/nalgeon/sqlean/releases/download/${version}/sqlean-macos-arm64.zip";
      hash = "sha256-G8qhU4xCuw0qXQhkkJqvV0dbDiuow4BwVXeQsOxaeFo=";
    }
    else if system == "x86_64-darwin"
    then {
      url = "https://github.com/nalgeon/sqlean/releases/download/${version}/sqlean-macos-x64.zip";
      hash = "sha256-tIao4VRmC8hip+6sA76jOe8dN5n022/COd0M3+AkQww=";
    }
    else if system == "aarch64-linux"
    then {
      url = "https://github.com/nalgeon/sqlean/releases/download/${version}/sqlean-linux-arm64.zip";
      hash = "sha256-B02nNIeQFSF8oQU3uUf5R/qvta8NgFyrQO63KJVOix8=";
    }
    else if system == "x86_64-linux"
    then {
      url = "https://github.com/nalgeon/sqlean/releases/download/${version}/sqlean-linux-x64.zip";
      hash = "sha256-vyon1pZ7i+sjrONSq9PkJ7vC2tFHfFNNw8qp0ng0Pdw=";
    }
    else
      (
        throw "sqlean: unsupported platform ${stdenv.hostPlatform.system}"
      );

  sharedLibExt = stdenv.hostPlatform.extensions.sharedLibrary;
in
  stdenv.mkDerivation {
    pname = "sqlean";
    inherit version;

    src = fetchzip {
      inherit (platformAsset) url hash;
      stripRoot = false;
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/bin

      find . -maxdepth 1 -type f -name "*${sharedLibExt}" -exec install -Dm644 {} $out/lib/$(basename {}) \;

      if [ -f sqlean ]; then
        install -Dm755 sqlean $out/bin/sqlean
      elif [ -f sqlite3 ]; then
        install -Dm755 sqlite3 $out/bin/sqlean-sqlite3
      fi

      runHook postInstall
    '';

    meta = with lib; {
      description = "Bundled SQLite extension libraries from SQLean";
      homepage = "https://github.com/nalgeon/sqlean";
      license = licenses.mit;
      platforms = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
  }
