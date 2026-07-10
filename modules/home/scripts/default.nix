# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/default.nix
# ----------------------------------------------------------------------------
# Scripts module aggregator; the terminal rail rides the desktop app graph.

{
  host,
  lib,
  pkgs,
  ...
}: {
  imports =
    [./fmt.nix ./loc.nix]
    ++ lib.optionals (host.os == "darwin") [./terminal.nix];

  home.packages = [
    pkgs.forge-provision
  ];
}
