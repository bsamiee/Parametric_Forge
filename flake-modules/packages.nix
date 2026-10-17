# Title         : packages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/packages.nix
# ----------------------------------------------------------------------------
# Public packages and apps as folds of overlays/manifest.nix projection rows: `projection.package` publishes the attr, `projection.app` wraps its CLI.
# `package-manifest` is the machine-readable ledger and rides the same smoke checks.
_: let
  manifest = import ../overlays/manifest.nix;
in {
  perSystem = {overlaidPkgs, ...}: let
    inherit (overlaidPkgs) lib;
    rowsWhere = field:
      lib.filterAttrs (_: row: row.projection.${field} or false) manifest.packages;
  in {
    packages =
      lib.mapAttrs (name: _: overlaidPkgs.${name}) (rowsWhere "package")
      // {inherit (overlaidPkgs) package-manifest;};

    apps = lib.mapAttrs (name: _: {
      type = "app";
      program = lib.getExe overlaidPkgs.${name};
    }) (rowsWhere "app");
  };
}
