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

    # Rows differ from aria2's defaults (`aria2c --help=#all`).
    settings = {
      # --- [PERFORMANCE_SETTINGS]
      max-connection-per-server = 8;
      split = 8;
      min-split-size = "1M";
      max-concurrent-downloads = 4;

      # --- [RELIABILITY_SETTINGS]
      continue = true;
      retry-wait = 30;
      timeout = 600;

      # --- [OPTIMIZATION]
      file-allocation = "none"; # Faster startup for SSDs
      disk-cache = "32M";

      # --- [PROTOCOL_SETTINGS]
      enable-http-pipelining = true;
      user-agent = "aria2";

      # --- [BITTORRENT_SETTINGS]
      enable-dht6 = true;
      bt-enable-lpd = true;
      bt-seed-unverified = true;
    };
  };
}
