{
  lib,
  pkgs,
  ...
}: let
  actConfig = [
    # --- [RUNNER_IMAGES]
    "-P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest"
    "-P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04"
    "-P ubuntu-24.04-arm=ghcr.io/catthehacker/ubuntu:act-24.04"
    "-P ubuntu-22.04=ghcr.io/catthehacker/ubuntu:act-22.04"

    # --- [PERFORMANCE]
    "--action-offline-mode"
  ];
in {
  home.packages = [pkgs.act];
  xdg.configFile."act/actrc".text = lib.concatStringsSep "\n" actConfig;
}
