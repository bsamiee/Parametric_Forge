# Title         : rust-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/rust-tools.nix
# ----------------------------------------------------------------------------
# Rust development environment with modern tooling.

{ pkgs, ... }:

with pkgs;
[
  # --- Core Rust Toolchain ---------------------------------------------------
  rustup # Toolchain management (includes rustc, cargo, rustfmt, clippy, rust-analyzer)

  # --- Essential Development Tools -------------------------------------------
  bacon # Background compiler with live feedback TUI
  cargo-edit # Add/remove/upgrade dependencies from CLI (provides cargo-upgrade)
  cargo-watch # Auto-rebuild on file changes
  cargo-binstall # Fast binary installation (avoids compilation)

  # --- Code Quality & Analysis ----------------------------------------------
  cargo-deny # Check dependencies for security/license issues
  cargo-machete # Find unused dependencies (better than udeps)
  cargo-outdated # Check for outdated dependencies
  cargo-bloat # Analyze binary size (find what takes space)
  cargo-audit # Security vulnerability scanner
  cargo-generate # Project template generator

  # --- Performance & Caching ------------------------------------------------
  sccache # Compilation caching for faster builds

  # --- Documentation & Project Management -----------------------------------
  mdbook # Documentation generator (Rust's standard)
  cargo-expand # Show macro-expanded code
]
