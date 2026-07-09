# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/default.nix
# ----------------------------------------------------------------------------
# Scripts module aggregator; integration glue rides the desktop app graph.
{
  host,
  lib,
  pkgs,
  ...
}: {
  imports =
    [./analysis]
    ++ lib.optionals (host.os == "darwin") [./integration];

  home.packages = [
    pkgs.forge-provision
  ];
}
