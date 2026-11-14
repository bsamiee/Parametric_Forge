{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  redeploy = pkgs.writeShellApplication {
    name = "redeploy";
    runtimeInputs = [config.programs.nh.package];
    text = ''
      job=(nh darwin "''${1:?usage: redeploy build|switch [nh args]}" ${host.flakeRoot} -H ${host.name} "''${@:2}")
      [[ $1 != switch ]] || job=(${lib.getExe config.forge.monitoring.heartbeat} mac-jobs_redeploy "''${job[@]}")
      exec "''${job[@]}"
    '';
  };
in {
  home.packages = [redeploy];
}
