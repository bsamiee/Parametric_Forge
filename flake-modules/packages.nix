# Title         : packages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/packages.nix
# ----------------------------------------------------------------------------
# Public packages and apps. CLI-intended outputs get symmetric apps; sqlean
# stays package-only (extension library set consumed by sqlite-forge).
_: {
  perSystem = {
    config,
    forgePkgs,
    ...
  }: let
    mkApp = package: {
      type = "app";
      program = forgePkgs.lib.getExe package;
    };
  in {
    packages = {
      inherit (forgePkgs) duckdb forge-provision sqlite-forge sqlean;
      default = forgePkgs.forge-provision;
    };

    apps = {
      duckdb = mkApp forgePkgs.duckdb;
      forge-provision = mkApp forgePkgs.forge-provision;
      sqlite-forge = mkApp forgePkgs.sqlite-forge;
      default = config.apps.forge-provision;
    };
  };
}
