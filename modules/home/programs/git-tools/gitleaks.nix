# Title         : gitleaks.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/gitleaks.nix
# ----------------------------------------------------------------------------
# Gitleaks secrets detection configuration

{ config, lib, pkgs, ... }:

let
  tomlFormat = pkgs.formats.toml { };

  gitleaksConfig = {
    title = "Gitleaks Configuration";

    # Extend default gitleaks rules for comprehensive coverage
    extend = {
      useDefault = true;
    };

    # --- Global Allowlists --------------------------------------------------
    allowlists = [
      {
        description = "Global allowlist for common safe patterns";
        paths = [
          ".gitleaksignore"
          ".gitignore"
          "*.md"
          "*.txt"
          "*.log"
          "**/test/**"
          "**/tests/**"
          "**/example/**"
          "**/examples/**"
          "**/node_modules/**"
          "**/dist/**"
          "**/build/**"
          "**/target/**"
          "**/.nix-store/**"
          "**/package-lock.json"
          "**/yarn.lock"
          "**/Cargo.lock"
          "**/flake.lock"
        ];

        regexes = [
          "example[_-]?key"
          "test[_-]?key"
          "demo[_-]?key"
          "fake[_-]?key"
          "dummy[_-]?key"
          "placeholder"
          "your[_-]?key[_-]?here"
          "/nix/store/[a-z0-9]{32}-.*"
          "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
          "^(example|test|demo).*==$"
        ];

        commits = [];
      }
    ];
  };
in
{
  home.packages = [ pkgs.gitleaks ];
  xdg.configFile."gitleaks/gitleaks.toml".source =
    tomlFormat.generate "gitleaks-config" gitleaksConfig;
}
