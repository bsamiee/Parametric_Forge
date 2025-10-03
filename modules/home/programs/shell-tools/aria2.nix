# Title         : aria2.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/aria2.nix
# ----------------------------------------------------------------------------
# Multi-protocol download utility with parallel connections

{ config, lib, pkgs, ... }:

{
  programs.aria2 = {
    enable = true;

    settings = {
      # --- Performance Settings ---------------------------------------------
      max-connection-per-server = 8;    # Balanced parallel connections
      split = 8;                        # Split files into 8 segments
      min-split-size = "1M";            # Don't split files smaller than 1MB
      max-concurrent-downloads = 4;     # Reasonable parallel downloads

      # --- Reliability Settings ---------------------------------------------
      continue = true;                  # Resume partial downloads
      max-tries = 5;                    # Retry failed downloads
      retry-wait = 30;                  # Wait 30s between retries
      timeout = 600;                    # 10 minute timeout per download

      # --- Optimization -----------------------------------------------------
      file-allocation = "none";         # Faster startup for SSDs
      disk-cache = "32M";               # Memory cache for better performance

      # --- Connection Settings ----------------------------------------------
      max-overall-download-limit = 0;   # No global speed limit
      max-download-limit = 0;           # No per-download speed limit
      lowest-speed-limit = 0;           # No minimum speed requirement

      # --- File Management --------------------------------------------------
      auto-file-renaming = true;        # Avoid overwriting files
      allow-overwrite = false;          # Don't overwrite by default

      # --- Protocol Settings ------------------------------------------------
      enable-http-keep-alive = true;    # Reuse HTTP connections
      enable-http-pipelining = true;    # HTTP/1.1 pipelining
      user-agent = "aria2";             # Default user agent

      # --- SSL/TLS Settings (macOS AppleTLS workaround) ---------------------
      check-certificate = false;        # Disable cert check (AppleTLS bug #2277)

      # --- BitTorrent Settings ----------------------------------------------
      enable-dht = true;                # DHT for magnet links (already default)
      enable-dht6 = true;               # IPv6 DHT support
      bt-enable-lpd = true;             # Local Peer Discovery
      bt-seed-unverified = true;        # Seed without hash check
      bt-max-peers = 55;                # Max peers per torrent
    };
  };
}
