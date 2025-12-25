# Title         : act.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/act.nix
# ----------------------------------------------------------------------------
# Local GitHub Actions runner configuration
{
  lib,
  pkgs,
  config,
  ...
}:
let
  actConfig = [
    # --- Apple Silicon Compatibility ------------------------------------------
    "--container-architecture=linux/amd64"

    # --- Runner Images --------------------------------------------------------
    "-P ubuntu-latest=catthehacker/ubuntu:act-latest"
    "-P ubuntu-22.04=catthehacker/ubuntu:act-22.04"
    "-P ubuntu-20.04=catthehacker/ubuntu:act-20.04"

    # --- Performance ----------------------------------------------------------
    "--action-offline-mode"
  ];
in {
  home.packages = [pkgs.act];
  xdg.configFile."act/actrc".text = lib.concatStringsSep "\n" actConfig;
}
