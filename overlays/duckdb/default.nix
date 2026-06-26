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
  version = "1.5.4";
  system = stdenvNoCC.hostPlatform.system;

  platformAsset =
    if system == "aarch64-darwin"
    then {
      url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-osx-universal.zip";
      hash = "sha256-xdjLYNfVzra7lPzlrkoXzIFtsZwhtrteDSNIs7IkA1k=";
    }
    else if system == "aarch64-linux"
    then {
      url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-linux-arm64.zip";
      hash = "sha256-N38D+58Xq1p48o+CnL/LUzPairPC0HiPJ2lPgd937Sk=";
    }
    else if system == "x86_64-linux"
    then {
      url = "https://github.com/duckdb/duckdb/releases/download/v${version}/duckdb_cli-linux-amd64.zip";
      hash = "sha256-Hy+nJPsFSz2+Gpy9E95bdpl9hQ5wh+x2K6iNsE4BgM8=";
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
      platforms = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
  }
