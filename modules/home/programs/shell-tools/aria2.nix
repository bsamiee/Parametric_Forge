# Title         : aria2.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/aria2.nix
# ----------------------------------------------------------------------------
# Multi-protocol download utility with parallel connections
_: {
  programs.aria2 = {
    enable = true;

    settings = {
      # --- [PERFORMANCE_SETTINGS]
      max-connection-per-server = 8;
      split = 8;
      min-split-size = "1M";
      max-concurrent-downloads = 4;

      # --- [RELIABILITY_SETTINGS]
      continue = true;
      max-tries = 5;
      retry-wait = 30;
      timeout = 600;

      # --- [OPTIMIZATION]
      file-allocation = "none"; # Faster startup for SSDs
      disk-cache = "32M";

      # --- [CONNECTION_SETTINGS]
      max-overall-download-limit = 0;
      max-download-limit = 0;
      lowest-speed-limit = 0;

      # --- [FILE_MANAGEMENT]
      auto-file-renaming = true;
      allow-overwrite = false;

      # --- [PROTOCOL_SETTINGS]
      enable-http-keep-alive = true;
      enable-http-pipelining = true;
      user-agent = "aria2";

      # --- [BITTORRENT_SETTINGS]
      enable-dht = true;
      enable-dht6 = true;
      bt-enable-lpd = true;
      bt-seed-unverified = true;
      bt-max-peers = 55;
    };
  };
}
