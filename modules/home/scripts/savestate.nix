{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "savestate" ''
      exec ${pkgs.python3}/bin/python3 -I ${./savestate.py} "$@"
    '')
  ];
}
