# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/sqlean/default.nix
# ----------------------------------------------------------------------------
# SQLean - bundled SQLite extension libraries (https://github.com/nalgeon/sqlean)

{ lib, stdenv, fetchzip }:

let
  version = "0.27.2";

  platformAsset =
    if stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64 then {
      url = "https://github.com/nalgeon/sqlean/releases/download/${version}/sqlean-macos-arm64.zip";
    } else if stdenv.hostPlatform.isDarwin then {
      url = "https://github.com/nalgeon/sqlean/releases/download/${version}/sqlean-macos-x64.zip";
    } else if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64 then {
      url = "https://github.com/nalgeon/sqlean/releases/download/${version}/sqlean-linux-arm64.zip";
    } else if stdenv.hostPlatform.isLinux then {
      url = "https://github.com/nalgeon/sqlean/releases/download/${version}/sqlean-linux-x64.zip";
    } else (
      throw "sqlean: unsupported platform ${stdenv.hostPlatform.system}"
    );

  sharedLibExt = stdenv.hostPlatform.extensions.sharedLibrary;
in

stdenv.mkDerivation {
  pname = "sqlean";
  inherit version;

  src = fetchzip {
    inherit (platformAsset) url;
    hash = "sha256-7zH//98V7H3LCa/Z+CH1aldBOMMIjFaoV1sYI3fo3Ac=";
    stripRoot = false;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/bin

    find . -type f -name "*${sharedLibExt}" -maxdepth 1 -exec install -Dm644 {} $out/lib/$(basename {}) \;

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
    platforms = platforms.unix;
  };
}
