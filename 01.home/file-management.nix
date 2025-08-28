# Title         : 01.home/file-management.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/file-management.nix
# ----------------------------------------------------------------------------
# Centralized file management for all configuration files
# Platform-aware configuration deployment with Darwin/NixOS support

{
  lib,
  pkgs,
  myLib,
  ...
}:

{
  # --- XDG Configuration Files ----------------------------------------------
  xdg.configFile = {
    # --- Terminal Configuration ---------------------------------------------
    "wezterm/wezterm.lua".source = ./00.core/configs/apps/wezterm.lua;
    # Note: starship.toml handled by programs.starship.settings in shell-tools.nix
    "ccstatusline/settings.json".source = ./00.core/configs/apps/ccstatusline-settings.json;

    # --- Window Management (macOS) ------------------------------------------
    "yabai/yabairc".source = ./00.core/configs/apps/yabairc; # Yabai window manager config
    "borders/bordersrc".source = ./00.core/configs/apps/borders/bordersrc; # JankyBorders window borders config

    # --- SketchyBar Configuration (Modern SbarLua) --------------------------
    # Modern Lua-based SketchyBar configuration with XDG Base Directory compliance
    # Target: ~/.config/sketchybar/ (XDG_CONFIG_HOME/sketchybar/)
    #
    # Deployment Structure:
    # ├── init.lua              - SbarLua main entry point
    # ├── modules/              - Lua configuration modules
    # │   ├── bar.lua          - Bar configuration (position, appearance)
    # │   ├── colors.lua       - Dracula color scheme definitions
    # │   ├── icons.lua        - Icon mappings and Nerd Font symbols
    # │   └── items/           - Individual bar item configurations
    # │       ├── spaces.lua   - Yabai space indicators
    # │       ├── battery.lua  - Battery status with charging icons
    # │       ├── clock.lua    - Date/time display
    # │       ├── cpu.lua      - CPU usage monitoring
    # │       └── volume.lua   - Audio control with mute toggle
    # ├── providers/           - Binary providers for system data
    # │   └── system-stats     - Native system stats provider
    # ├── helpers/             - Utility scripts
    # │   └── icon_map.sh      - App icon mapping script
    # └── helpers/             - Utility scripts and icon mappings
    #
    # Main SbarLua configuration
    "sketchybar/init.lua".source = ./00.core/configs/apps/sketchybar/init.lua;
    # Lua modules directory - contains bar, colors, icons, and item modules
    "sketchybar/modules" = {
      source = ./00.core/configs/apps/sketchybar/modules;
      recursive = true;
    };
    # Helper scripts directory for utilities and icon mapping
    "sketchybar/helpers/.keep".text = ""; # Ensure helpers directory exists

    # --- System Information -------------------------------------------------
    "fastfetch/config.json".source = ./00.core/configs/apps/fastfetch/config.json;

    # --- File Manager (Yazi) ------------------------------------------------
    "yazi/yazi.toml".source = ./00.core/configs/apps/yazi/yazi.toml;
    "yazi/keymap.toml".source = ./00.core/configs/apps/yazi/keymap.toml;
    "yazi/theme.toml".source = ./00.core/configs/apps/yazi/theme.toml;
    "yazi/package.toml".source = ./00.core/configs/apps/yazi/package.toml;
    "yazi/init.lua".source = ./00.core/configs/apps/yazi/init.lua;
    # Dracula flavor deployment - proper directory structure
    "yazi/flavors/dracula.yazi/flavor.toml".source = ./00.core/configs/apps/yazi/dracula-flavor.toml;

    # --- Git Configuration --------------------------------------------------
    "git/ignore".source = ./00.core/configs/git/gitignore;
    "git/attributes".source = ./00.core/configs/git/gitattributes;
    "gitleaks/gitleaks.toml".source = ./00.core/configs/git/gitleaks.toml;
    # --- Language Server Configurations -------------------------------------
    # Python (global configs - work via environment variables)
    "pypoetry/config.toml".source = ./00.core/configs/poetry.toml;
    "ruff/ruff.toml".source = ./00.core/configs/languages/ruff.toml;
    "mypy/mypy.ini".source = ./00.core/configs/languages/mypy.ini;
    "basedpyright/config.json".source = ./00.core/configs/languages/basedpyright.json;
    # Shell
    "shellcheck/shellcheckrc".source = ./00.core/configs/languages/shellcheckrc;
    # Package managers
    "npm/npmrc".source = ./00.core/configs/npmrc;
    "cargo/config.toml".source = ./00.core/configs/languages/cargo.toml;
    # Lua
    "luarocks/config.lua".source = ./00.core/configs/languages/luarocks.lua;
    # --- Formatting Tools ---------------------------------------------------
    "yamllint/config".source = ./00.core/configs/formatting/.yamllint.yml;

    # --- File & Directory Operations Tools ----------------------------------
    # Eza (modern ls replacement)
    "eza/theme.yml".source = ./00.core/configs/system/eza/theme.yml; # Dracula-inspired theme
    # Fd (modern find replacement)
    "fd/ignore".source = ./00.core/configs/system/fd/ignore; # Global ignore patterns

    # --- Text Processing & Search Tools -------------------------------------
    # Bat (enhanced cat)
    "bat/config".source = ./00.core/configs/system/bat/config; # Bat configuration
    # Ripgrep (ultra-fast text search)
    "ripgrep/config".source = ./00.core/configs/system/ripgrep/config; # Global ripgrep configuration

    # --- File Analysis & Diff Tools ----------------------------------------
    "tokei/tokei.toml".source = ./00.core/configs/system/tokei/tokei.toml; # Code statistics config

    # --- System Monitoring Tools ---------------------------------------------
    "procs/config.toml".source = ./00.core/configs/system/procs/config.toml; # Process viewer config
    "dust/config.toml".source = ./00.core/configs/system/dust/config.toml; # Directory size analyzer config
    # Bottom is managed by home-manager's programs.bottom module

    # --- Media Processing ---------------------------------------------------
    # ImageMagick
    "ImageMagick/policy.xml".source = ./00.core/configs/media-tools/imagemagick/policy.xml;

    # --- Container Runtime Configurations -----------------------------------
    "docker/config.json".source = ./00.core/configs/containers/docker-config.json;
    "colima/default/colima.yaml".source = ./00.core/configs/containers/colima.yaml;
    "containers/containers.conf".source = ./00.core/configs/containers/containers.conf; # Podman
    "containers/registries.conf".source = ./00.core/configs/containers/registries.conf; # Podman
    "containers/storage.conf".source = ./00.core/configs/containers/storage.conf; # Podman
  };
  # --- Home Files (Non-XDG) -------------------------------------------------
  home.file = {
    # --- DNS Tools ----------------------------------------------------------
    ".digrc".source = ./00.core/configs/system/dig/.digrc;
    # --- SQLite Configuration -----------------------------------------------
    ".sqliterc".source = ./00.core/configs/languages/sqliterc;
    # --- Root-level Rust configs (Rust tools expect these here) -------------
    ".rustfmt.toml".source = ./00.core/configs/languages/rustfmt.toml;
    ".cargo-deny.toml".source = ./00.core/configs/languages/cargo-deny.toml;
    # These tools look for configs in home root and don't support env vars:
    ".prettierrc".source = ./00.core/configs/formatting/.prettierrc;
    ".ncurc.json".source = ./00.core/configs/node/.ncurc.json;
    ".stylua.toml".source = ./00.core/configs/languages/.stylua.toml;
    ".yamlfmt".source = ./00.core/configs/formatting/.yamlfmt;
    ".editorconfig".source = ./00.core/configs/formatting/.editorconfig;
    # --- Container Runtime Files (Home Root) --------------------------------
    ".dockerignore".source = ./00.core/configs/containers/.dockerignore;
    # --- TLDR Configuration -------------------------------------------------
    ".tldrrc".source = ./00.core/configs/system/tldr/.tldrrc;

    # --- Window Management (macOS - Non-XDG) --------------------------------
    ".skhdrc".source = ./00.core/configs/apps/skhdrc; # skhd doesn't support XDG

    # --- SketchyBar Fonts (Local Fonts Directory) ---------------------------
    # Note: App font now installed via Homebrew cask (font-sketchybar-app-font)

    # --- Asset Folder Files -------------------------------------------------
  }
  // (myLib.build.deployDir ./00.core/configs/apps/claude ".claude")
  // {
    # Deploy prettierrc to .claude for hooks that expect it there
    ".claude/.prettierrc".source = ./00.core/configs/formatting/.prettierrc;
  };

  # --- Asset Bin Scripts (Added to PATH) ------------------------------------
  home.packages =
    let
      binDir = ./02.assets/bin;
      binPackage = myLib.build.mkBinPackage {
        inherit pkgs;
        source = binDir;
        name = "forge-scripts";
      };
    in
    lib.optionals (binPackage != null) [ binPackage ];

  # --- Platform-Specific Data Files -----------------------------------------
  xdg.dataFile = {
    # Pandoc
    "pandoc/defaults/forge.yaml".source = ./00.core/configs/media-tools/pandoc/defaults.yaml;
  }
  // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
    # Desktop entries for Linux (not needed on macOS which uses .app bundles)
    "applications/code.desktop" = {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Visual Studio Code
        Exec=code %F
        Icon=code
        MimeType=text/plain;text/x-shellscript;application/json;
        Categories=Development;TextEditor;
      '';
    };
  };
}
