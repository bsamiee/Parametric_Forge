# Title         : 01.home/darwin/services/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/default.nix
# ----------------------------------------------------------------------------
# User-level launchd agents for macOS.

{
  myLib,
  lib,
  pkgs,
  ...
}:

{
  # --- Service Helpers ------------------------------------------------------
  _module.args.userServiceHelpers = lib.mapAttrs (_: f: f pkgs) myLib.launchd;

  # --- Import User Service Modules ------------------------------------------
  imports = [
    ./xdg-daemons.nix
    ./exclusion-daemons.nix
    ./op-daemons.nix
    ./npm-check-daemon.nix
  ];
}
