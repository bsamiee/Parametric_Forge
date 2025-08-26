# Title         : sysadmin.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/sysadmin.nix
# ----------------------------------------------------------------------------
# System administration and network diagnostic tools.

{ pkgs, ... }:

with pkgs;
[
  # --- Network Analysis -----------------------------------------------------
  bandwhich # Terminal bandwidth monitor by process/connection
  iperf # Network performance testing (iperf3)
  whois # Domain information lookup
  speedtest-cli # Internet speed testing from terminal
  bind # DNS tools (includes dig)

  # --- System Utilities -----------------------------------------------------
  parallel-full # GNU parallel for parallel command execution
  watchexec # watch → File watcher that runs commands on changes
  tldr # man → Simplified, practical man pages with examples
]
