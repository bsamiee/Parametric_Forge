# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/nodejs-bin/default.nix
# ----------------------------------------------------------------------------
# Official Node.js binary distribution for cache-safe installs on every host.
# pnpm-only rail: npm/npx never reach the installed output; corepack rows are
# idempotent guards (upstream bundles corepack only for Node <25).
{
  fetchurl,
  lib,
  stdenvNoCC,
}: let
  version = "26.5.0";
  dists = {
    aarch64-darwin = {
      arch = "darwin-arm64";
      hash = "sha256-SCMdYgTspr4T5sUYTf3/odZK2IiANkzCz7GY+HLLKxM=";
    };
    x86_64-linux = {
      arch = "linux-x64";
      hash = "sha256-n2GVKPHbXdxB3M9UIRBm+0IijWmhVnM8acudbMkuNYw=";
    };
    aarch64-linux = {
      arch = "linux-arm64";
      hash = "sha256-A23wtJZi67NQ61bxysYDaZsentHiYD7hKf79pHNHkDA=";
    };
  };
  dist =
    dists.${stdenvNoCC.hostPlatform.system}
    or (throw "nodejs-bin: no official distribution row for ${stdenvNoCC.hostPlatform.system}");
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
      url = "https://nodejs.org/dist/v${version}/node-v${version}-${dist.arch}.tar.xz";
      inherit (dist) hash;
    };

    sourceRoot = "node-v${version}-${dist.arch}";

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
      platforms = builtins.attrNames dists;
    };
  }
