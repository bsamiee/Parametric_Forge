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

  # --- Database Tools -------------------------------------------------------
  # SQLite Extensions
  sqlite # Base SQLite 3.50.2 (newer than macOS default 3.43.2)
  sqlite-vec # Vector search SQLite extension (semantic pattern matching)
  sqlite-interactive # Interactive SQLite CLI with enhanced features
  sqlite-utils # Python CLI tool for SQLite database manipulation
  libspatialite # OGC-compliant spatial SQL engine (GIS operations, coordinate transformations)

  # SQL Quality Tools
  sqlfluff # SQL linter and formatter (multi-dialect)
  sqlcheck # Anti-pattern detection for SQL queries

  # Analytical Databases
  duckdb # Analytical SQL database - Parquet/CSV/JSON preview and analysis

  # --- Code Quality & Linting -----------------------------------------------
  shellcheck # Shell script linter
  shfmt # Shell formatter
  bash-language-server # LSP for shell scripts

  # --- Language Servers -----------------------------------------------------
  taplo # TOML formatter and linter
  taplo-lsp # TOML language server
  yamlfmt # YAML formatter (Google's, no Python deps)
  yamllint # YAML linter
  yaml-language-server # YAML language server
  marksman # Markdown LSP with wiki-link support

  # --- Data Processing ------------------------------------------------------
  # jq → Managed by programs.jq in shell-tools.nix
  yq-go # YAML processor (Go version)
  fx # Interactive JSON viewer
  jless # JSON pager
  miller # CSV/TSV/JSON processor with SQL-like queries - Enhanced data preview

  # --- Testing Frameworks ---------------------------------------------------
  bats # Bash testing framework - Test shell scripts and commands
]
