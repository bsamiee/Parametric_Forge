{
  inputs,
  lib,
  ...
}: let
  cache = "bsamiee";
in {
  determinateNix = {
    shellCompletions.enable = false;

    # --- [REGISTRY]
    registry = lib.mapAttrs (_: flake: {inherit flake;}) (removeAttrs inputs ["self"]);

    customSettings = {
      trusted-users = ["root" "@admin"];
      nix-path = ["nixpkgs=flake:nixpkgs"];

      # --- [USER_DIRECTORIES]
      use-xdg-base-directories = true;

      # --- [PERFORMANCE]
      max-substitution-jobs = 32;
      http-connections = 50;
      download-buffer-size = 268435456;

      # --- [BUILD_BEHAVIOR]
      keep-going = true;
      warn-dirty = false;
      show-trace = true;
      log-lines = 100;
      connect-timeout = 10;

      # --- [STORE_MANAGEMENT]
      auto-optimise-store = true;

      # --- [CACHE_CONFIGURATION]
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
    };

    # --- [DETERMINATE_NIXD]
    determinateNixd = {
      builder.state = "disabled";
      telemetry.sentry.endpoint = null;
    };
  };
}
