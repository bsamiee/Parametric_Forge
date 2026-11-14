{
  lib,
  pkgs,
  ...
}: let
  toolRows = (import ../../../../overlays/manifest.nix).extensions.uv-tools.rows;
  commands = lib.concatMapAttrs (package: row:
    lib.genAttrs row.commands (command:
      pkgs.writeShellScriptBin command ''
        exec ${pkgs.uv}/bin/uvx ${lib.optionalString (row ? python) "--python ${row.python} "}--from ${lib.escapeShellArg "${package}[${lib.concatStringsSep "," row.extras}]==${row.version}"} ${command} "$@"
      ''))
  toolRows;
in {
  home.packages = lib.attrValues commands;
}
