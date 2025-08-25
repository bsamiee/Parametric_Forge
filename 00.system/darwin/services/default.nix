# Title         : 00.system/darwin/services/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/services/default.nix
# ----------------------------------------------------------------------------
# System-level launchd daemons infrastructure for Darwin.

{ ... }:

{
  # --- Import System Service Modules ----------------------------------------
  imports = [
    ./maintenance-daemon.nix # Nix store optimization and health monitoring
    # Future system daemons:
    # ./postgresql.nix      # Database server
    # ./redis.nix           # Cache server
    # ./tailscale.nix       # VPN service
  ];
  # --- Global Service Configuration -----------------------------------------
  # System-wide launchd configuration can go here
}
