# Title         : 01.home/exclusions.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/exclusions.nix
# ----------------------------------------------------------------------------
# Tagged exclusion patterns for services to filter by type/location.

{ myLib, ... }:

{
  # --- Combined Module Arguments --------------------------------------------
  _module.args = {
    # --- Export Exclusion Patterns ------------------------------------------
    exclusions = [
      # --- JavaScript/Node --------------------------------------------------
      {
        pattern = "node_modules";
        types = [
          "dev"
          "heavy"
        ];
      }
      {
        pattern = "bower_components";
        types = [
          "dev"
          "heavy"
        ];
      }
      {
        pattern = ".next";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = ".nuxt";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = ".turbo";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = ".vercel";
        types = [ "dev" ];
      }
      {
        pattern = "npm";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "pnpm";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "yarn";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      # --- Python -----------------------------------------------------------
      {
        pattern = "__pycache__";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = "*.pyc";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = ".venv";
        types = [
          "dev"
          "heavy"
        ];
      }
      {
        pattern = "venv";
        types = [
          "dev"
          "heavy"
        ];
      }
      {
        pattern = ".env";
        types = [ "dev" ];
      }
      {
        pattern = ".tox";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = ".pytest_cache";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = ".mypy_cache";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = ".ruff_cache";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = "*.egg-info";
        types = [ "dev" ];
      }
      {
        pattern = "pip";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "pypoetry";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "pylint";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "ruff";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "basedpyright";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "mypy";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "pytest";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "uv";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      # --- Rust/Cargo -------------------------------------------------------
      {
        pattern = "target";
        types = [
          "dev"
          "heavy"
        ];
      }
      {
        pattern = "cargo";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "cargo/registry";
        types = [
          "cache"
          "heavy"
        ];
        location = "xdg-data";
      }
      {
        pattern = "rust-analyzer";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "sccache";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      # --- Go ---------------------------------------------------------------
      {
        pattern = "vendor";
        types = [
          "dev"
          "heavy"
        ];
      }
      {
        pattern = "go-build";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "go/pkg";
        types = [
          "cache"
          "heavy"
        ];
        location = "xdg-data";
      }
      # --- Lua --------------------------------------------------------------
      {
        pattern = "*.luac";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = "lua_modules";
        types = [
          "dev"
          "heavy"
        ];
      }
      {
        pattern = ".luarocks";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = "lua-language-server";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      # --- Java/JVM ---------------------------------------------------------
      {
        pattern = ".gradle";
        types = [
          "dev"
          "cache"
        ];
      }
      {
        pattern = "gradle";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "gradle/caches";
        types = [
          "cache"
          "heavy"
        ];
        location = "xdg-data";
      }
      {
        pattern = ".m2";
        types = [
          "cache"
          "heavy"
        ];
      }
      {
        pattern = "maven";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      # --- Build Outputs ----------------------------------------------------
      {
        pattern = "build";
        types = [ "dev" ];
      }
      {
        pattern = "dist";
        types = [ "dev" ];
      }
      {
        pattern = "out";
        types = [ "dev" ];
      }
      {
        pattern = "_build";
        types = [ "dev" ];
      }
      {
        pattern = ".bin";
        types = [ "dev" ];
      }
      {
        pattern = "obj";
        types = [ "dev" ];
      }
      # --- Version Control --------------------------------------------------
      {
        pattern = ".git";
        types = [
          "vcs"
          "index"
        ];
      }
      {
        pattern = ".svn";
        types = [
          "vcs"
          "index"
        ];
      }
      {
        pattern = ".hg";
        types = [
          "vcs"
          "index"
        ];
      }
      {
        pattern = ".bzr";
        types = [ "vcs" ];
      }
      # --- IDEs/Editors -----------------------------------------------------
      {
        pattern = ".idea";
        types = [
          "ide"
          "index"
        ];
      }
      {
        pattern = ".vscode";
        types = [
          "ide"
          "index"
        ];
      }
      {
        pattern = "*.swp";
        types = [ "temp" ];
      }
      {
        pattern = "*.swo";
        types = [ "temp" ];
      }
      {
        pattern = "*~";
        types = [ "temp" ];
      }
      {
        pattern = ".DS_Store";
        types = [
          "system"
          "index"
        ];
      }
      {
        pattern = "Thumbs.db";
        types = [
          "system"
          "index"
        ];
      }
      # --- macOS/Xcode ------------------------------------------------------
      {
        pattern = "DerivedData";
        types = [
          "dev"
          "heavy"
          "index"
        ];
      }
      {
        pattern = "*.xcodeproj";
        types = [
          "dev"
          "index"
        ];
      }
      {
        pattern = "*.xcworkspace";
        types = [
          "dev"
          "index"
        ];
      }
      {
        pattern = "xcuserdata";
        types = [ "dev" ];
      }
      # --- Container Tools --------------------------------------------------
      {
        pattern = "docker";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "colima";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "podman";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "lazydocker";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "dive";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "buildkit";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      # --- Shell Tools ------------------------------------------------------
      {
        pattern = "bat";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "direnv";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "fd";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "zoxide";
        types = [ "cache" ];
        location = "xdg-data";
      }
      {
        pattern = "broot";
        types = [ "cache" ];
        location = "xdg-data";
      }
      {
        pattern = "mcfly";
        types = [ "cache" ];
        location = "xdg-data";
      }
      {
        pattern = "nix-index";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      # --- System/Tools -----------------------------------------------------
      {
        pattern = "nix";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "fontconfig";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "shellcheck";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "bazel";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "op";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "ssh";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "claude";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      {
        pattern = "claude/logs";
        types = [
          "logs"
          "cache"
        ];
        location = "xdg-cache";
      }
      {
        pattern = "sqlite_history";
        types = [ "cache" ];
        location = "xdg-cache";
      }
      # --- Data Directories -------------------------------------------------
      {
        pattern = "Trash";
        types = [ "backup" ];
        location = "xdg-data";
      }
      {
        pattern = "backups";
        types = [ "backup" ];
        location = "xdg-data";
      }
      {
        pattern = "logs";
        types = [ "logs" ];
        location = "xdg-state";
      }
      {
        pattern = "npm/lib";
        types = [
          "cache"
          "heavy"
        ];
        location = "xdg-data";
      }
      {
        pattern = "docker-machine";
        types = [ "cache" ];
        location = "xdg-data";
      }
      # --- System Paths -----------------------------------------------------
      {
        pattern = "/nix/store";
        types = [ "system" ];
        location = "absolute";
      }
      {
        pattern = "/nix/var";
        types = [ "system" ];
        location = "absolute";
      }
      {
        pattern = "Library/Caches";
        types = [
          "cache"
          "system"
        ];
        location = "home";
      }
      {
        pattern = "Library/Logs";
        types = [ "logs" ];
        location = "home";
      }
    ];
    # --- Helper Attributes --------------------------------------------------
    exclusionHelpers = {
      # Project search directories (relative to home)
      projectRoots = [
        "Documents"
        "Projects"
        "Development"
        "Code"
        "src"
        "repos"
      ];
    };
    # --- Export Filter Functions --------------------------------------------
    inherit (myLib) exclusionFilters;
  };
}
