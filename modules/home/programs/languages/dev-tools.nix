# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/dev-tools.nix
# ----------------------------------------------------------------------------
# Language-agnostic tooling: linters, formatters, and helpers shared across
# multiple ecosystems.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- Shell Tooling ------------------------------------------------------
    shellcheck # POSIX shell static analysis
    shfmt # Shell script formatter

    # --- TOML ---------------------------------------------------------------
    taplo # CLI formatter/linter

    # --- YAML ---------------------------------------------------------------
    yamlfmt # YAML formatter (Google)
    yamllint # YAML linter

    # --- JSON ---------------------------------------------------------------
    jq # Lightweight command-line JSON processor

    # --- General Data Tools -------------------------------------------------
    yq-go # YAML/JSON/TOML processor (yq)
    miller # CSV/TSV/JSON processor
  ];
}
