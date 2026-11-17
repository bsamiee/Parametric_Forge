{
  lib,
  pkgs,
  ...
}: let
  toolRows = (import ../../../../overlays/manifest.nix).extensions.uv-tools.rows;
  commands = lib.concatMapAttrs (package: row:
    lib.genAttrs row.commands (command:
      pkgs.writeShellScriptBin command ''
        exec ${pkgs.uv}/bin/uvx ${lib.optionalString (row ? python) "--python ${row.python} "}${lib.concatMapStrings (dep: "--with ${lib.escapeShellArg dep} ") (row.withPackages or [])}--from ${lib.escapeShellArg "${package}[${lib.concatStringsSep "," row.extras}]==${row.version}"} ${command} "$@"
      ''))
  toolRows;
in {
  home.packages = lib.attrValues commands;

  # uvx and Python runs outside a project use 3.13, the newest every tool row has wheels for; a project's own pin still wins.
  xdg.configFile."uv/.python-version".text = "3.13\n";
}
