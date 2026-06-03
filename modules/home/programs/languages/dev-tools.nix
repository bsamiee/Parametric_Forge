# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/languages/dev-tools.nix
# ----------------------------------------------------------------------------
# Language-agnostic tooling: linters, formatters, and helpers shared across
# multiple ecosystems.
{pkgs, ...}: let
  dotnet-combined = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnet-sdk_8
    pkgs.dotnet-sdk_9
    pkgs.dotnet-sdk_10
  ];
in {
  home.packages = with pkgs; [
    # --- Shell Tooling ------------------------------------------------------
    shellcheck # POSIX shell static analysis
    shfmt # Shell script formatter

    # --- YAML ---------------------------------------------------------------
    yamlfmt # YAML formatter (Google)
    yamllint # YAML linter

    # --- JSON ---------------------------------------------------------------
    jq # Lightweight command-line JSON processor

    # --- General Data Tools -------------------------------------------------
    git-lfs # Required by Homebrew update-reset and repos with LFS-backed fixtures
    yq-go # YAML/JSON/TOML processor (yq)
    miller # CSV/TSV/JSON processor

    # --- .NET ---------------------------------------------------------------
    dotnet-combined
  ];

  # DOTNET_ROOT required for omnisharp and other SDK-discovery tools.
  # Re-evaluated on every rebuild — store path stays current.
  home.sessionVariables.DOTNET_ROOT = "${dotnet-combined}";
}
