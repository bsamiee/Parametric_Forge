_: let
  manifest = import ../overlays/manifest.nix;
in {
  perSystem = {pkgs, ...}: let
    inherit (pkgs) lib;
    rowsWhere = field:
      lib.filterAttrs (_: row: row.projection.${field} or false) manifest.packages;
  in {
    packages = lib.mapAttrs (name: _: pkgs.${name}) (rowsWhere "package");

    apps = lib.mapAttrs (name: _: {
      type = "app";
      program = lib.getExe pkgs.${name};
    }) (rowsWhere "app");
  };
}
