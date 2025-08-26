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
    "starship.toml".source = ./00.core/configs/apps/starship.toml;
    "ccstatusline/settings.json".source = ./00.core/configs/apps/ccstatusline-settings.json;

    # --- Git Configuration --------------------------------------------------
    "git/ignore".source = ./00.core/configs/git/gitignore;
    "git/attributes".source = ./00.core/configs/git/gitattributes;
    # --- Language Server Configurations -------------------------------------
    # Nix
    "nil/nil.toml".source = ./00.core/configs/languages/nil.toml; # TODO: nil only reads from project root, move to templates
    # Python
    "basedpyright/basedpyright.json".source = ./00.core/configs/languages/basedpyright.json; # TODO: basedpyright reads from project root, move to templates
    "pypoetry/config.toml".source = ./00.core/configs/poetry.toml; # OK: Poetry respects XDG
    "ruff/ruff.toml".source = ./00.core/configs/languages/ruff.toml; # OK: Ruff respects XDG
    "mypy/mypy.ini".source = ./00.core/configs/languages/mypy.ini; # OK: Mypy uses MYPY_CONFIG_FILE env var
    # Rust
    "rust-analyzer/rust-analyzer.json".source = ./00.core/configs/languages/rust-analyzer.json; # TODO: rust-analyzer reads from project root, move to templates
    "clippy/clippy.toml".source = ./00.core/configs/languages/clippy.toml; # TODO: clippy reads from project root, move to templates
    "clippy/clippy-lints.toml".source = ./00.core/configs/languages/clippy-lints.toml; # TODO: clippy reads from project root, move to templates
    # Markdown
    "marksman/marksman.toml".source = ./00.core/configs/languages/marksman.toml; # TODO: marksman reads from project root, move to templates
    # Shell
    "shellcheck/shellcheckrc".source = ./00.core/configs/languages/shellcheckrc; # OK: shellcheck respects XDG
    # Package managers
    "npm/npmrc".source = ./00.core/configs/npmrc; # OK: npm uses NPM_CONFIG_USERCONFIG env var
    "cargo/config.toml".source = ./00.core/configs/languages/cargo.toml; # OK: cargo respects XDG
    # Lua
    "luarocks/config.lua".source = ./00.core/configs/languages/luarocks.lua; # OK: luarocks uses LUAROCKS_CONFIG env var
    # TODO: lua-language-server - .luarc.json should be per-project, add to templates when needed
    # TODO: busted - .busted config should be per-project (testing framework)
    # TODO: luacov - .luacov config should be per-project (coverage tool)
    # TODO: pytest - pytest.ini or setup.cfg should be per-project, add to templates when needed
    # --- Formatting Tools ---------------------------------------------------
    "taplo/taplo.toml".source = ./00.core/configs/formatting/.taplo.toml; # TODO: taplo only reads from project root, move to templates
    "yamllint/config".source = ./00.core/configs/formatting/.yamllint.yml; # OK: yamllint uses YAMLLINT_CONFIG_FILE env var

    # --- Container Runtime Configurations -----------------------------------
    "docker/config.json".source = ./00.core/configs/containers/docker-config.json;
    "colima/default/colima.yaml".source = ./00.core/configs/containers/colima.yaml;
    "containers/containers.conf".source = ./00.core/configs/containers/containers.conf; # Podman
    "containers/registries.conf".source = ./00.core/configs/containers/registries.conf; # Podman
    "containers/storage.conf".source = ./00.core/configs/containers/storage.conf; # Podman
    # TODO: dive - Add dive/config.yaml for UI preferences and keybindings when needed
    # TODO: hadolint - Add hadolint.yaml for linting rules and ignored warnings when needed
  };
  # --- Home Files (Non-XDG) -------------------------------------------------
  home.file = {
    # --- SQLite Configuration ------------------------------------------------
    ".sqliterc".source = ./00.core/configs/languages/sqliterc;
    # --- Root-level Rust configs (Rust tools expect these here) -------------
    ".rustfmt.toml".source = ./00.core/configs/languages/rustfmt.toml;
    ".cargo-deny.toml".source = ./00.core/configs/languages/cargo-deny.toml;
    # These tools look for configs in home root and don't support env vars:
    ".prettierrc".source = ./00.core/configs/formatting/.prettierrc;
    ".stylua.toml".source = ./00.core/configs/languages/.stylua.toml;
    ".yamlfmt".source = ./00.core/configs/formatting/.yamlfmt;
    ".editorconfig".source = ./00.core/configs/formatting/.editorconfig;
    # --- Container Runtime Files (Home Root) --------------------------------
    ".dockerignore".source = ./00.core/configs/containers/.dockerignore;
    # --- PostgreSQL Formatter ------------------------------------------------
    ".pg_format".source = ./00.core/configs/formatting/pg_format; # TODO: pgformatter only reads from ~/, doesn't support XDG

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
  xdg.dataFile = lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
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
