# Title         : packages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/packages.nix
# ----------------------------------------------------------------------------
# Public packages and apps as folds of overlays/manifest.nix projection rows:
# `projection.package` publishes the attr, `projection.app` wraps its CLI,
# `projection.default = true` names the default. forge-package-manifest is the
# machine-readable ledger and rides the same smoke checks.
_: let
  manifest = import ../overlays/manifest.nix;
in {
  perSystem = {
    config,
    forgePkgs,
    ...
  }: let
    inherit (forgePkgs) lib;
    rowsWhere = field:
      lib.filterAttrs (_: row: row.projection.${field} or false) manifest.packages;
    # Exactly one row may carry projection.default; zero or many is a named eval fault.
    defaultName = let
      names = builtins.attrNames (rowsWhere "default");
    in
      if builtins.length names == 1
      then lib.head names
      else throw "overlays/manifest.nix: exactly one projection.default row required, found ${toString (builtins.length names)}";
    mkApp = package: {
      type = "app";
      program = lib.getExe package;
    };
  in {
    packages =
      lib.mapAttrs (name: _: forgePkgs.${name}) (rowsWhere "package")
      // {
        inherit (forgePkgs) forge-package-manifest;
        default = forgePkgs.${defaultName};
      };

    apps =
      lib.mapAttrs (name: _: mkApp forgePkgs.${name}) (rowsWhere "app")
      // {
        default =
          config.apps.${defaultName}
          or (throw "overlays/manifest.nix: the projection.default row '${defaultName}' must also set projection.app");
      };
  };
}
