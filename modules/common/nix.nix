# Title         : nix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/common/nix.nix
# ----------------------------------------------------------------------------
# Determinate Nix custom settings; /etc/nix/nix.conf stays Determinate-owned.
_: let
  gib = n: n * 1024 * 1024 * 1024;
in {
  # Settings land in module-generated /etc/nix/nix.custom.conf at switch.
  # Determinate owns eval-cores, lazy-trees, netrc-file, ssl-cert-file, and
  # experimental-features in /etc/nix/nix.conf; those keys are rejected here.
  determinateNix = {
    enable = true;

    customSettings = {
      # Local admin group; @wheel holds only root on this host.
      trusted-users = ["root" "@admin"];

      # --- Performance ------------------------------------------------------
      max-substitution-jobs = 32;
      http-connections = 50;

      # --- Build Behavior ---------------------------------------------------
      keep-going = true;
      builders-use-substitutes = true;
      keep-outputs = true;
      min-free-check-interval = 300;
      max-silent-time = 3600;
      warn-dirty = false;
      accept-flake-config = true;
      show-trace = true;
      log-lines = 100;
      connect-timeout = 10;

      # --- Store Management -------------------------------------------------
      min-free = gib 5;
      max-free = gib 50;

      # --- Cache Configuration ------------------------------------------------
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
  };

  # --- Nixpkgs Configuration ------------------------------------------------
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
  };
}
