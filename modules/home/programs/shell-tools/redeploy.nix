{
  config,
  host,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  redeploy = pkgs.writeShellApplication {
    name = "redeploy";
    runtimeInputs = [pkgs.cachix config.programs.nh.package];
    text = ''
      job=(cachix watch-exec ${osConfig.cachix.cache} -- nh darwin "''${1:?usage: redeploy build|switch [nh args]}" ${host.flakeRoot} -H ${host.name} "''${@:2}")
      [[ $1 != switch ]] || job=(${lib.getExe config.forge.monitoring.heartbeat} mac-jobs_redeploy "''${job[@]}")
      exec "''${job[@]}"
    '';
  };
in {
  home.packages = [redeploy];
}
