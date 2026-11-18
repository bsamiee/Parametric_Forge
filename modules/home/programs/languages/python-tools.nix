{
  lib,
  pkgs,
  ...
}: let
  toolRows = (import ../../../../overlays/manifest.nix).extensions.uv-tools.rows;
  commands = lib.concatMapAttrs (package: row:
    lib.genAttrs row.commands (command:
      pkgs.writeShellScriptBin command ''
        exec ${pkgs.uv}/bin/uvx ${lib.concatMapStrings (dep: "--with ${lib.escapeShellArg dep} ") (row.withPackages or [])}--from ${lib.escapeShellArg "${package}[${lib.concatStringsSep "," (row.extras or [])}]==${row.version}"} ${command} "$@"
      ''))
  toolRows;
in {
  home.packages = lib.attrValues commands;

  xdg.configFile."uv/.python-version".text = "3.13\n";
}
