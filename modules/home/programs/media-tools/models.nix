{
  lib,
  pkgs,
  ...
}: let
  modelRows = (import ../../../../overlays/manifest.nix).extensions.models.rows;
in {
  home.packages = [
    pkgs.whisper-cpp
  ];

  xdg.dataFile = lib.mapAttrs' (name: row:
    lib.nameValuePair "models/${name}" {
      source = pkgs.fetchurl {
        url = "${row.base}/${name}";
        inherit (row) hash;
      };
    })
  modelRows;
}
