# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/default.nix
# ----------------------------------------------------------------------------
# Nix tool inventory; nixd carries the only import-worthy configuration.
{
  host,
  pkgs,
  ...
}: {
  imports = [./nixd.nix];

  programs = {
    # nh on PATH with NH_FLAKE at the Forge checkout: bare `nh darwin switch|build`, `nh search`, `nh clean all`. Its wrapper carries
    # nix-output-monitor; dix is its diff engine.
    nh = {
      enable = true;
      flake = host.flakeRoot;
    };
    # Command-not-found with the pre-built package database; comma rides the same database.
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
  };

  home.packages = [
    pkgs.alejandra # Uncompromising Nix code formatter
    pkgs.cachix # Official Cachix CLI; authenticates from ambient CACHIX_AUTH_TOKEN, never `cachix authtoken` (a literal-token config file)
    pkgs.deadnix # Dead Nix code detector
    pkgs.dix # Closure diff between generations (the engine nh diffs with)
    pkgs.flake-checker # Flake input health checks
    pkgs.nix-diff # Derivation-level diff explanation
    pkgs.nix-tree # Interactive closure browser
    pkgs.nixd # Nix language server
    pkgs.nurl # Fetcher call with hash for any source URL (GitHub, GitLab, git, crates, PyPI, ...)
    pkgs.statix # Nix antipattern linter
  ];
}
