# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/nix.nix
# ----------------------------------------------------------------------------
# Determinate Nix custom settings; /etc/nix/nix.conf stays Determinate-owned. One settings vocabulary, two projections: Darwin rides
# determinateNix customSettings, NixOS rides the thin determinate module plus nix.settings — both land the values in /etc/nix/nix.custom.conf at
# switch. The OS branch keys on the static host context, never on pkgs (module fixpoint safety).
{
  host,
  lib,
  ...
}: let
  gib = n: n * 1024 * 1024 * 1024;

  # Local admin group per OS: Darwin admin, NixOS wheel.
  adminGroups = {
    darwin = ["@admin"];
    nixos = ["@wheel"];
  };

  # Determinate owns /etc/nix/nix.conf (eval-cores, lazy-trees, caches, experimental-features); the darwin module asserts against netrc-file and
  # ssl-cert-file here — auth rides determinateNixd.authentication rows.
  customSettings = {
    trusted-users = ["root"] ++ adminGroups.${host.os};

    # --- [PERFORMANCE]
    max-substitution-jobs = 32;
    http-connections = 50;

    # --- [BUILD_BEHAVIOR]
    keep-going = true;
    builders-use-substitutes = true;
    keep-outputs = true;
    min-free-check-interval = 300;
    max-silent-time = 3600;
    warn-dirty = false;
    # accept-flake-config stays default-false: flakes must not auto-apply nixConfig.
    show-trace = true;
    log-lines = 100;
    connect-timeout = 10;

    # --- [STORE_MANAGEMENT]
    # Client-side pressure floor backing the determinate-nixd automatic GC.
    min-free = lib.mkDefault (gib 5);
    max-free = lib.mkDefault (gib 50);

    # --- [CACHE_CONFIGURATION]
    # Determinate appends FlakeHub/installer caches via extra-* in nix.conf.
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://bsamiee.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "bsamiee.cachix.org-1:b/WAIj/ImX6pkDc6SUVYHJoL/yJ7E4MIA+e7uA9rdwQ="
    ];
    narinfo-cache-positive-ttl = 86400;
  };

  # OS projection rows: Darwin rides determinateNix customSettings; NixOS rides nix.settings — determinate.enable defaults true and the module
  # reroutes generated nix.conf to nix.custom.conf and swaps the daemon for determinate-nixd.
  osProjections = {
    darwin = {
      determinateNix = {
        enable = true;

        # Background GC is determinate-nixd-owned (free-space targeted); the forge-nix-maintenance agent owns generation retention and optimise.
        determinateNixd.garbageCollector.strategy = "automatic";

        inherit customSettings;
      };
    };
    nixos = {
      nix.settings = customSettings;
    };
  };
in
  {
    # --- [NIXPKGS_CONFIGURATION]
    nixpkgs.config = {
      allowUnfree = true;
      allowBroken = false;
    };
  }
  // osProjections.${host.os}
