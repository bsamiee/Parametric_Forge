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
  # --- Build Systems & Automation -------------------------------------------
  just # make → Modern task runner with better syntax
  cmake # Cross-platform build system generator
  pkg-config # Helper tool for compiling applications and libraries
  hyperfine # time → Command-line benchmarking tool
  pre-commit # Git hook framework for code quality
  # watchexec # watch → Better file watcher (TODO: Add after review)
  # parallel # GNU parallel processing (TODO: Add after review)

  # --- Database Tools -------------------------------------------------------
  sqlite-interactive # Enhanced CLI (includes base sqlite functionality)
  sqlite-vec # Vector search extension
  sqlite-utils # Python CLI tool
  libspatialite # Spatial SQL engine
  sqlfluff # SQL linter/formatter
  sqlcheck # Anti-pattern detection
  duckdb # Analytical SQL database

  # --- Code Quality & Linting -----------------------------------------------
  shellcheck
  shfmt
  bash-language-server
  taplo
  taplo-lsp
  yamlfmt # YAML formatter (Google's, no Python deps)
  yamllint # YAML linter
  yaml-language-server # YAML language server
  marksman # Markdown LSP with wiki-link support
  joker # Clojure/EDN linter used by GokuRakuJoudo

  # --- Data Processing ------------------------------------------------------
  # jq → Managed by programs.jq in shell-tools.nix
  yq-go
  fx
  jless
  miller

  # --- Testing Frameworks ---------------------------------------------------
  bats

  # --- Modern CLI Tools (TODO: Add after review) ---------------------------
  # zellij
  # skim
  # nushell
]
