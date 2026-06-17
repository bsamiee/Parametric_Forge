# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/duckdb/default.nix
# ----------------------------------------------------------------------------
# DuckDB CLI overlay. nixpkgs currently lags the official stable macOS CLI.
{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}: let
  version = "1.5.3";

  platformAsset =
    if stdenvNoCC.hostPlatform.isDarwin
    then {
      url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-osx-universal.zip";
      hash = "sha256-rnmfEGrKG7dAsEBkSPE7qRVY1ZGXR1y2oPNJ224Xcho=";
    }
    else if stdenvNoCC.hostPlatform.isLinux && stdenvNoCC.hostPlatform.isAarch64
    then {
      url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-linux-arm64.zip";
      hash = "sha256-XiOZQoeTZC6ZTxWExH1J9MWLe07CKX6kpSI1OmxVODU=";
    }
    else if stdenvNoCC.hostPlatform.isLinux
    then {
      url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-linux-amd64.zip";
      hash = "sha256-NcrvH+y8jX4sB95P0s3vxRieybqeHMoij7GhxIzFKoo=";
    }
    else
      (
        throw "duckdb: unsupported platform ${stdenvNoCC.hostPlatform.system}"
      );
in
  stdenvNoCC.mkDerivation {
    pname = "duckdb";
    inherit version;

    src = fetchurl {
      inherit (platformAsset) url hash;
    };

    nativeBuildInputs = [unzip];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      runHook preUnpack
      unzip "$src"
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 duckdb "$out/bin/duckdb"
      runHook postInstall
    '';

    meta = with lib; {
      description = "DuckDB command line client";
      homepage = "https://duckdb.org/";
      license = licenses.mit;
      mainProgram = "duckdb";
      platforms = platforms.unix;
    };
  }
