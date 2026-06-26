# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/nodejs-bin/default.nix
# ----------------------------------------------------------------------------
# Official Node.js binary distribution for cache-safe Darwin installs.
{
  fetchurl,
  lib,
  stdenvNoCC,
}: let
  version = "26.3.1";
  arch = "darwin-arm64";
in
  stdenvNoCC.mkDerivation {
    pname = "nodejs-bin";
    inherit version;

    src = fetchurl {
      url = "https://nodejs.org/dist/v${version}/node-v${version}-${arch}.tar.xz";
      hash = "sha256-SayiKowpksFmiLqlEqewDEGkYI6WdfyqgVNHZ78RFs4=";
    };

    sourceRoot = "node-v${version}-${arch}";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -R . "$out"
      runHook postInstall
    '';

    meta = {
      description = "Node.js ${version} official binary distribution";
      homepage = "https://nodejs.org/";
      license = lib.licenses.mit;
      mainProgram = "node";
      platforms = ["aarch64-darwin"];
    };
  }
