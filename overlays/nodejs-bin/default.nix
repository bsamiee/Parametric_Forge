# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/nodejs-bin/default.nix
# ----------------------------------------------------------------------------
# Official Node.js binary distribution for cache-safe Darwin installs.
# pnpm-only rail: npm/npx never reach the installed output; corepack rows are
# idempotent guards (upstream bundles corepack only for Node <25).
{
  fetchurl,
  lib,
  stdenvNoCC,
}: let
  version = "26.5.0";
  arch = "darwin-arm64";
  stripRows = [
    "bin/npm"
    "bin/npx"
    "bin/corepack"
    "lib/node_modules/npm"
    "lib/node_modules/corepack"
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "nodejs-bin";
    inherit version;

    src = fetchurl {
      url = "https://nodejs.org/dist/v${version}/node-v${version}-${arch}.tar.xz";
      hash = "sha256-SCMdYgTspr4T5sUYTf3/odZK2IiANkzCz7GY+HLLKxM=";
    };

    sourceRoot = "node-v${version}-${arch}";

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -R . "$out"
      ${lib.concatMapStringsSep "\n" (row: ''rm -rf "$out/${row}"'') stripRows}
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
