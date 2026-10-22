# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/nix.nix
# ----------------------------------------------------------------------------
# Determinate Nix custom settings; /etc/nix/nix.conf stays Determinate-owned and determinateNix.customSettings lands these values in
# /etc/nix/nix.custom.conf at switch. Owns the Cachix cache name; the home graph reads it through osConfig.
{
  config,
  lib,
  ...
}: let
  gib = n: n * 1024 * 1024 * 1024;
  inherit (config.cachix) cache;
in {
  # Cachix takes the cache name as an argument and reads no variable for it, so the deploy push reads this option beside the substituter row.
  options.cachix.cache = lib.mkOption {
    type = lib.types.str;
    default = "bsamiee";
    readOnly = true;
    description = "Name of the Cachix binary cache this machine substitutes from and pushes built store paths to.";
  };

  config = {
    # --- [NIXPKGS_CONFIGURATION]
    nixpkgs.config.allowUnfree = true;

    # Determinate owns /etc/nix/nix.conf (eval-cores, lazy-trees, caches, experimental-features); the darwin module asserts against netrc-file and
    # ssl-cert-file here — auth rides determinateNixd.authentication rows. Background GC is determinate-nixd-owned by its own default
    # (garbageCollector.strategy automatic, free-space targeted); generation retention and optimise are manual (`nix-collect-garbage -d`,
    # `nix store optimise`).
    determinateNix.customSettings = {
      trusted-users = ["root" "@admin"];

      # --- [USER_DIRECTORIES]
      # Profile, defexpr, and channel links under $XDG_STATE_HOME/nix instead of ~/.nix-profile, ~/.nix-defexpr, and ~/.nix-channels; nix-daemon.sh
      # reads the state link when it exists, and the per-user package profile already lives in /etc/profiles (useUserPackages).
      use-xdg-base-directories = true;

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
      min-free = gib 5;
      max-free = gib 50;

      # --- [CACHE_CONFIGURATION]
      # Determinate appends FlakeHub/installer caches via extra-* in nix.conf.
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://${cache}.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "${cache}.cachix.org-1:b/WAIj/ImX6pkDc6SUVYHJoL/yJ7E4MIA+e7uA9rdwQ="
      ];
      narinfo-cache-positive-ttl = 86400;
    };
  };
}
