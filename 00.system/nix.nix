# Title         : 00.system/nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/nix.nix
# ----------------------------------------------------------------------------
# Universal Nix daemon settings and garbage collection.

{
  config,
  lib,
  pkgs,
  context,
  ...
}:

{
  nix = {
    enable = true;
    package = pkgs.nixVersions.latest;
    settings = {
      # --- Features ---------------------------------------------------------
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "ca-derivations"
        "recursive-nix"
        "fetch-tree" # Faster Git fetching with shallow clones
        "pipe-operators" # |> and <| operators for better syntax
        "fetch-closure" # Fast binary cache imports at eval time
        "dynamic-derivations" # Enhanced derivation management
        "verified-fetches" # Git signature verification
      ];
      # --- Security ---------------------------------------------------------
      trusted-users = lib.mkForce (
        if context.isDarwin then
          [
            "@admin"
            "root"
          ]
        else
          [
            "@wheel"
            "root"
          ]
      );
      allowed-users = [ "*" ];

      # --- Performance ------------------------------------------------------
      max-jobs = "auto";
      cores = 0;
      max-substitution-jobs = 32;
      http-connections = 50;
      http2 = true;

      # --- Build Optimization -----------------------------------------------
      keep-outputs = false;
      keep-derivations = false;
      compress-build-log = true;
      keep-failed = false;
      keep-going = true;
      always-allow-substitutes = true; # Force substitution over building
      builders-use-substitutes = true; # Builders can use binary caches
      fsync-store-paths = false; # Skip fsync for better performance

      # --- Store Management -------------------------------------------------
      min-free-check-interval = 300;
      max-silent-time = 3600;
      min-free = 4 * 1024 * 1024 * 1024;
      max-free = 16 * 1024 * 1024 * 1024;

      # --- Platform Settings ------------------------------------------------
      sandbox = if context.isDarwin then "relaxed" else true;
      use-sqlite-wal = true;
      use-xdg-base-directories = true;

      # --- Developer Experience ---------------------------------------------
      warn-dirty = false;
      accept-flake-config = true;
      allow-import-from-derivation = true;
      show-trace = true;
      log-lines = 100;
      run-diff-hook = true;

      # --- Binary Caches ----------------------------------------------------
      substituters = lib.mkForce [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://bsamiee.cachix.org"
      ];
      trusted-public-keys = lib.mkForce [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Ky7bkq5CX+/rkCWyvRCYg3Fs="
        "bsamiee.cachix.org-1:b/WAIj/ImX6pkDc6SUVYHJoL/yJ7E4MIA+e7uA9rdwQ="
      ];
      # --- Cache Performance ------------------------------------------------
      narinfo-cache-negative-ttl = 60;
      narinfo-cache-positive-ttl = 86400;
      eval-cache = true;
      tarball-ttl = 300;

      # --- Network Resilience -----------------------------------------------
      connect-timeout = 5;
      download-attempts = 3;
      stalled-download-timeout = 300;
    };
    extraOptions = ''
      fallback = true
      keep-build-log = true
    '';

    # --- Garbage Collection -------------------------------------------------
    gc = lib.mkIf config.nix.enable (
      {
        automatic = true;
        options = "--delete-older-than 7d --max-freed $((5 * 1024 * 1024 * 1024))";
      }
      // (
        if context.isDarwin then
          {
            interval = {
              Hour = 3;
              Minute = 0;
              Weekday = 0;
            };
          }
        else
          {
            dates = "weekly";
            persistent = true;
          }
      )
    );
    optimise.automatic = lib.mkIf config.nix.enable true;
  };
  # --- Nixpkgs Configuration ------------------------------------------------
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = false;
      allowUnsupportedSystem = false;
    };
    overlays = [ ];
  };
}
