# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/pnpm/default.nix
# ----------------------------------------------------------------------------
# pnpm CLI overlay. nixpkgs currently lags the npm-published pnpm 11 line.
{
  fetchurl,
  pnpm_11,
}:
pnpm_11.overrideAttrs (_old: rec {
  version = "11.8.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/pnpm/-/pnpm-${version}.tgz";
    hash = "sha512-wfXnxMskHI8XS3Q4UdgvQrgCMkr8iw8Ra5atsVqgZmSUjd42lgo7oQebpbSyndAUATW5S1tfUmNZIknWjlVfJg==";
  };
})
