# Title         : 00.system/darwin/services/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/services/default.nix
# ----------------------------------------------------------------------------
# System-level launchd daemons infrastructure for Darwin.

_:

{
  imports = [
    ./maintenance-daemon.nix
    ./clt-daemon.nix
  ];
}
