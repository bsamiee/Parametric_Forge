{
  config,
  host,
  pkgs,
  ...
}: let
  redeploy = pkgs.writeShellApplication {
    name = "redeploy";
    runtimeInputs = [config.programs.nh.package];
    text = ''
      exec nh darwin "''${1:?usage: redeploy build|switch [nh args]}" ${host.flakeRoot} -H ${host.name} "''${@:2}"
    '';
  };
in {
  home.packages = [redeploy];
}
