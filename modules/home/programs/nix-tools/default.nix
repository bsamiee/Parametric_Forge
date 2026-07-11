# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/default.nix
# ----------------------------------------------------------------------------
# Nix tool inventory; nixd carries the only import-worthy configuration.
{pkgs, ...}: {
  imports = [./nixd.nix];

  # Command-not-found with the pre-built package database; comma rides the same database.
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.nix-index-database.comma.enable = true;

  home.packages = [
    pkgs.alejandra # Uncompromising Nix code formatter
    pkgs.deadnix # Dead Nix code detector
    pkgs.flake-checker # Flake input health checks
    pkgs.nh # Nix build/switch/clean helper
    pkgs.nix-diff # Derivation-level diff explanation
    pkgs.nix-output-monitor # Nix build output monitor
    pkgs.nix-prefetch-github # GitHub source prefetching for fetchFromGitHub
    pkgs.nix-tree # Interactive closure browser
    pkgs.nixd # Nix language server
    pkgs.nvd # Closure diff between generations
    pkgs.statix # Nix antipattern linter
  ];
}
