# Title         : flake/formatting.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /flake/formatting.nix
# ----------------------------------------------------------------------------
# Code formatting via treefmt-nix for languages currently in use

{ inputs, ... }:

{
  # --- Imports --------------------------------------------------------------
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        # --- Nix Ecosystem ----------------------------------------------------
        nixfmt.enable = true; # Official Nix formatter
        # NOTE: statix and deadnix are run separately in checks.nix for better control
        # They're disabled here to avoid duplicate work during treefmt runs
        # --- Shell Scripts ----------------------------------------------------
        shfmt = {
          enable = true;
          indent_size = 4; # Match project style
        };
        shellcheck.enable = true; # Shell script linter
        # --- Rust Ecosystem ---------------------------------------------------
        rustfmt.enable = true; # Official Rust formatter (for interface/)
        # --- Lua --------------------------------------------------------------
        stylua = {
          enable = true;
          includes = [ "*.lua" ]; # For wezterm.lua config
        };
        # --- Data Formats -----------------------------------------------------
        mdformat = {
          enable = true;
          includes = [
            "*.md"
            "*.markdown"
          ];
        };
        yamlfmt = {
          enable = true;
          includes = [
            "*.yml"
            "*.yaml"
          ];
        };
        taplo = {
          enable = true;
          includes = [ "*.toml" ];
        };
        jsonfmt = {
          enable = true;
          includes = [
            "*.json"
            "*.jsonc"
          ];
        };
      };
      # --- Per-formatter Settings --------------------------------------------
      settings = {
        formatter = {
          # Rust-specific settings
          rustfmt = {
            excludes = [
              "interface/target/**"
            ];
          };
          # Nix settings
          nixfmt = {
            options = [
              "--width"
              "120"
            ];
          };
        };
        # --- Global Exclusions ----------------------------------------------
        global.excludes = [
          # Version control
          ".git/**"
          ".gitignore"
          # Nix artifacts
          "flake.lock"
          "result"
          "result-*"
          # Development environments
          ".direnv/**"
          ".envrc"
          # Build artifacts
          "interface/target/**"
          # Backup files
          "*.backup"
          "*.bak"
          # OS files
          ".DS_Store"
          "Thumbs.db"
          # Project-specific exclusions
          "01.home/exclusions.nix" # Manual formatting for readability
          "00.DEPRECATED/**" # Don't format deprecated code
          ".kiro/**" # Kiro's managed files
          "interface/Cargo.lock" # Auto-generated
        ];
      };
    };
  };
}
