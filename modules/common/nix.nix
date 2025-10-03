# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/nix.nix
# ----------------------------------------------------------------------------
# Core Nix daemon configuration for both Darwin and NixOS

{ lib, pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  nix = {
    # Disable nix-darwin's Nix management for Determinate Nix compatibility
    enable = false;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "@admin" "@wheel" "root" ];
      allowed-users = [ "*" ];

      # --- Performance ------------------------------------------------------
      cores = 0;
      eval-cores = 0;                   # Enable parallel evaluation (Determinate Nix)
      max-substitution-jobs = 32;       # More parallel substitutions
      http-connections = 50;            # More parallel downloads (default 25)
      http2 = true;                     # Use HTTP/2 for better performance

      # --- Build Behavior ---------------------------------------------------
      keep-going = true;
      builders-use-substitutes = true;
      keep-outputs = true;              # Keep build dependencies
      keep-derivations = true;          # Keep .drv files
      compress-build-log = true;        # Save disk space
      use-sqlite-wal = true;            # Better SQLite performance
      eval-cache = true;                # Cache evaluation results
      min-free-check-interval = 300;    # Check free space every 5 min
      max-silent-time = 3600;           # Kill builds silent >1 hour
      # Developer experience
      warn-dirty = false;
      accept-flake-config = true;
      show-trace = true;                # Better error messages
      log-lines = 100;                  # More build log context
      # Network resilience
      connect-timeout = 10;                 # Connection timeout (seconds)
      stalled-download-timeout = 300;       # 5 minutes (default)
      download-attempts = 3;               # Retry failed downloads

      # --- Store Management -------------------------------------------------
      min-free = lib.mkDefault (5 * 1024 * 1024 * 1024);  # 5GB
      max-free = lib.mkDefault (50 * 1024 * 1024 * 1024); # 50GB

      # --- Cache Configuration ----------------------------------------------
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://bsamiee.cachix.org"       # Personal cache
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Ky7bkq5CX+/rkCWyvRCYg3Fs="
        "bsamiee.cachix.org-1:b/WAIj/ImX6pkDc6SUVYHJoL/yJ7E4MIA+e7uA9rdwQ="
      ];
      # Cache performance
      narinfo-cache-negative-ttl = 3600;   # 1 hour (default)
      narinfo-cache-positive-ttl = 86400;  # 1 day (vs 1 month default)
    };
  };

  # --- Post-build Hook Cachix Push ------------------------------------------
  nix.settings.post-build-hook = let
    cachixHook = pkgs.writeShellScript "cachix-hook" ''
      [ -n "''${CACHIX_AUTH_TOKEN:-}" ] && [ -n "''${OUT_PATHS:-}" ] && {
        ${pkgs.cachix}/bin/cachix push ''${CACHIX_CACHE:-bsamiee} $OUT_PATHS &>/dev/null &
      }
    '';
  in lib.mkDefault cachixHook;

  # --- Nixpkgs Configuration ------------------------------------------------
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
  };
}
