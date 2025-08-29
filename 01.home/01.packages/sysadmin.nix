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
  bind # DNS tools (includes dig, nslookup, host)
  wireshark-cli # Network protocol analyzer (tshark) - Required by pcap.yazi

  # --- System Monitoring ----------------------------------------------------
  parallel-full # GNU parallel for parallel command execution
  watchexec # watch → File watcher that runs commands on changes
  tldr # man → Simplified, practical man pages with examples
  fastfetch # neofetch → Fast system information tool with customization

  # --- File Transfer & Archive Management -----------------------------------
  rclone # Universal cloud storage CLI - sync/mount Google Drive, OneDrive, MEGA
         # TODO: Setup rclone configs for all cloud providers + create aliases for common operations
         # TODO: Add cloud-to-cloud transfer aliases (no local mounting due to 5TB vs 400GB constraint)
  transmission_4 # BitTorrent client v4 - Required by torrent-preview.yazi
  archivemount # Mount archives as filesystems - Required by archivemount.yazi

  # --- Security & Authentication --------------------------------------------
  _1password-cli # 1Password command-line tool for secrets management

  # --- macOS Management -----------------------------------------------------
  yabai # Tiling window manager for macOS
  skhd # Simple hotkey daemon for macOS
  sketchybar # Highly customizable macOS status bar
]
