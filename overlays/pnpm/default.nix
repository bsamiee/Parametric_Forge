# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/pnpm/default.nix
# ----------------------------------------------------------------------------
# pnpm CLI overlay. nixpkgs currently lags the npm-published pnpm 11 line.
# Shebangs re-target nodejs-bin: the nixpkgs nodejs-slim runtime aborts on a
# libuv kqueue EINTR assertion at teardown on Darwin; Node 26 exits clean.
{
  fetchurl,
  nodejs-bin_26,
  pnpm_11,
}:
pnpm_11.overrideAttrs (old: rec {
  version = "11.10.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/pnpm/-/pnpm-${version}.tgz";
    hash = "sha512-C3+LmAYAMZBMAX46QesYehbUDuuCm5XE+MsDaBdh/Eq1PdIZEVubRH9NzhoFohR2RGHn03AzkqnzL5URzoyGyA==";
  };

  postFixup =
    (old.postFixup or "")
    + ''
      for entry in "$out"/libexec/pnpm/bin/pnpm.{cjs,mjs} "$out"/libexec/pnpm/bin/pnpx.{cjs,mjs}; do
        sed -i "1s|^#!.*/node$|#!${nodejs-bin_26}/bin/node|" "$entry"
      done
    '';
})
