# Title         : 01.home/file-management.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/file-management.nix
# ----------------------------------------------------------------------------
# Centralized file management for all configuration files
# Platform-aware configuration deployment with Darwin/NixOS support

{
  config,
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

    # --- System Information -------------------------------------------------
    "fastfetch/config.json".source = ./00.core/configs/apps/fastfetch/config.json;

    # --- File Manager (Yazi) ------------------------------------------------
    "yazi/yazi.toml".source = ./00.core/configs/apps/yazi/yazi.toml;
    "yazi/keymap.toml".source = ./00.core/configs/apps/yazi/keymap.toml;
    "yazi/theme.toml".source = ./00.core/configs/apps/yazi/theme.toml;
    "yazi/init.lua".source = ./00.core/configs/apps/yazi/init.lua;
    # Dracula flavor deployment - proper directory structure
    "yazi/flavors/dracula.yazi/flavor.toml".source = ./00.core/configs/apps/yazi/dracula-flavor.toml;
    # Consolidated plugin package configuration
    "yazi/package.toml".source = ./00.core/configs/apps/yazi/packages.toml;

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
    "luacheck/.luacheckrc".source = ./00.core/configs/languages/.luacheckrc;
    # --- Formatting Tools ---------------------------------------------------
    "yamllint/config".source = ./00.core/configs/formatting/.yamllint.yml;

    # --- File & Directory Operations Tools ----------------------------------
    "eza/theme.yml".source = ./00.core/configs/system/eza/theme.yml; # Dracula-inspired theme
    "fd/ignore".source = ./00.core/configs/system/fd/ignore; # Global ignore patterns
    "duti/associations".source = ./00.core/configs/system/duti/associations; # Default application mappings

    # --- Text Processing & Search Tools -------------------------------------
    "bat/config".source = ./00.core/configs/system/bat/config; # Bat configuration
    "ripgrep/config".source = ./00.core/configs/system/ripgrep/config; # Global ripgrep configuration

    # --- File Analysis & Diff Tools ----------------------------------------
    "tokei/tokei.toml".source = ./00.core/configs/system/tokei/tokei.toml; # Code statistics config

    # --- System Monitoring Tools ---------------------------------------------
    "procs/config.toml".source = ./00.core/configs/system/procs/config.toml; # Process viewer config
    "dust/config.toml".source = ./00.core/configs/system/dust/config.toml; # Directory size analyzer config
    # Bottom is managed by home-manager's programs.bottom module

    # --- Media Processing ---------------------------------------------------
    "ImageMagick/policy.xml".source = ./00.core/configs/media-tools/imagemagick/policy.xml;

    # --- Container Runtime Configurations -----------------------------------
    "docker/config.json".source = ./00.core/configs/containers/docker-config.json;
    "colima/default/colima.yaml".source = ./00.core/configs/containers/colima.yaml;
    "containers/containers.conf".source = ./00.core/configs/containers/containers.conf; # Podman
    "containers/registries.conf".source = ./00.core/configs/containers/registries.conf; # Podman
    "containers/storage.conf".source = ./00.core/configs/containers/storage.conf; # Podman

    # --- UI Tools Configuration (Simple Files) -----------------------------
    "skhd/skhdrc".source = ./00.core/configs/apps/skhdrc;
    "borders/bordersrc" = {
      source = ./00.core/configs/apps/borders/bordersrc;
      executable = true;
    };
    # Hammerspoon (Lua automation)
    "hammerspoon/init.lua".source = ./00.core/configs/apps/hammerspoon/init.lua;
    "hammerspoon/forge/config.lua".source = ./00.core/configs/apps/hammerspoon/forge/config.lua;
    "hammerspoon/forge/state.lua".source = ./00.core/configs/apps/hammerspoon/forge/state.lua;
    "hammerspoon/forge/executor.lua".source = ./00.core/configs/apps/hammerspoon/forge/executor.lua;
    "hammerspoon/forge/policy.lua".source = ./00.core/configs/apps/hammerspoon/forge/policy.lua;
    "hammerspoon/forge/events.lua".source = ./00.core/configs/apps/hammerspoon/forge/events.lua;
    "hammerspoon/forge/integration.lua".source = ./00.core/configs/apps/hammerspoon/forge/integration.lua;
    "hammerspoon/forge/osd.lua".source = ./00.core/configs/apps/hammerspoon/forge/osd.lua;
    "hammerspoon/forge/auto.lua".source = ./00.core/configs/apps/hammerspoon/forge/auto.lua;
    "hammerspoon/forge/palette.lua".source = ./00.core/configs/apps/hammerspoon/forge/palette.lua;
    # Hammerspoon menubar assets (SF Symbols exported as PDF)
    "hammerspoon/assets" = {
      source = ./00.core/configs/apps/hammerspoon/assets;
      recursive = true;
    };
    # Karabiner-Elements (keyboard remapping)
    # Use Goku to generate karabiner.json from EDN; we do not symlink karabiner.json
    "karabiner/karabiner.edn".source = ./00.core/configs/apps/karabiner/karabiner.edn;
    "karabiner/assets/complex_modifications/parametric-forge.json".source = ./00.core/configs/apps/karabiner/assets/complex_modifications/parametric-forge.json;
    # --- Yabai Configuration ------------------------------------------------
    "yabai/yabairc" = {
      source = ./00.core/configs/apps/yabai/yabairc;
      executable = true;
    };
    "yabai/grid-anchors.sh" = {
      source = ./00.core/configs/apps/yabai/grid-anchors.sh;
      executable = true;
    };
    "yabai/rules-signals.sh" = {
      source = ./00.core/configs/apps/yabai/rules-signals.sh;
      executable = true;
    };
    "yabai/run-yabai.sh" = {
      source = ./00.core/configs/apps/yabai/run-yabai.sh;
      executable = true;
    };

  };

  # --- Home Activation Scripts ---------------------------------------------
  home.activation = {
     gokuCompileKarabiner = lib.hm.dag.entryAfter [ "createXdgDirs" ] ''
       echo "[Parametric Forge] Compiling karabiner.edn via goku (if available)..." >&2
       if command -v goku >/dev/null 2>&1; then
         export GOKU_EDN_CONFIG_FILE="${config.xdg.configHome}/karabiner/karabiner.edn"
         goku || true
       fi
     '';
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
    # --- Terminal Web Browser (w3m) -----------------------------------------
    ".w3m/config".source = ./00.core/configs/apps/w3m/config;
    ".w3m/keymap".source = ./00.core/configs/apps/w3m/keymap;
  };

  # --- Asset Bin Scripts (Added to PATH) -----------------------------------
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

  # --- Platform-Specific Data Files ----------------------------------------
  xdg.dataFile = {
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
