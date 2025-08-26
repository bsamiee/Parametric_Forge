# Title         : dev-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/dev-tools.nix
# ----------------------------------------------------------------------------
# General development tools for build, automation, and code quality.

{ pkgs, ... }:

with pkgs;
[
  # --- Development Tools ----------------------------------------------------
  just # make → Modern task runner with better syntax
  hyperfine # time → Command-line benchmarking tool
  jq # JSON processor and query tool
  pre-commit # Git hook framework

  # --- Code Quality & Linting -----------------------------------------------
  shellcheck # Shell script linter
  shfmt # Shell formatter
  bash-language-server # LSP for shell scripts

  # --- SQL Quality Tools -----------------------------------------------------
  sqlfluff # SQL linter and formatter (multi-dialect)
  sqlcheck # Anti-pattern detection for SQL queries

  # --- Config File Language Servers -----------------------------------------
  taplo # TOML formatter and linter
  taplo-lsp # TOML language server
  yamlfmt # YAML formatter (Google's, no Python deps)
  yamllint # YAML linter
  yaml-language-server # YAML language server
  marksman # Markdown LSP with wiki-link support

  # --- Data Processing ------------------------------------------------------
  yq-go # YAML processor (Go version)
  fx # Interactive JSON viewer
  jless # JSON pager
]
