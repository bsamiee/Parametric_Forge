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
  ...
}: let
  actConfig = [
    # --- Apple Silicon Compatibility ------------------------------------------
    "--container-architecture=linux/amd64"

    # --- Runner Images --------------------------------------------------------
    "-P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest"
    "-P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:act-24.04"
    "-P ubuntu-22.04=ghcr.io/catthehacker/ubuntu:act-22.04"

    # --- Performance ----------------------------------------------------------
    "--action-offline-mode"
  ];
in {
  home.packages = [pkgs.act];
  xdg.configFile."act/actrc".text = lib.concatStringsSep "\n" actConfig;
}
