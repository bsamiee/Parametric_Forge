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
        rustfmt.enable = true; # Official Rust formatter
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
          settings = {
            formatter = {
              pad_line_comments = 2; # Ensure 2 spaces before comments
              max_line_length = 120; # Match yamllint config
              indent = 4; # Match yamllint config
            };
          };
        };
        # Note: yamllint is run in checks.nix for linting validation
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
          # Backup files
          "*.backup"
          "*.bak"
          # OS files
          ".DS_Store"
          "Thumbs.db"
          # Project-specific exclusions
          "00.DEPRECATED/**" # Don't format deprecated code
          ".kiro/**" # Kiro's managed files
        ];
      };
    };
  };
}
