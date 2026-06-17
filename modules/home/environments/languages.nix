# Title         : languages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/languages.nix
# ----------------------------------------------------------------------------
# Programming language toolchains and environments
{
  config,
  pkgs,
  ...
}: let
  darwinMinVersion = pkgs.stdenv.hostPlatform.darwinMinVersion or "14.0";
in {
  home.sessionVariables = {
    # --- Python -------------------------------------------------------------
    PYTEST_CACHE_DIR = "${config.xdg.cacheHome}/pytest";
    RUFF_CACHE_DIR = "${config.xdg.cacheHome}/ruff";
    PYLINTHOME = "${config.xdg.cacheHome}/pylint";
    NOX_CACHE_DIR = "${config.xdg.cacheHome}/nox";
    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
    UV_NO_MANAGED_PYTHON = "1";
    UV_PYTHON_DOWNLOADS = "never";
    PYTHONDONTWRITEBYTECODE = "1";
    MACOSX_DEPLOYMENT_TARGET = darwinMinVersion;

    # --- Lua ----------------------------------------------------------------
    LUAROCKS_CONFIG = "${config.xdg.configHome}/luarocks/config.lua";
    LUAROCKS_TREE = "${config.xdg.dataHome}/luarocks";

    # --- Shell Linters ------------------------------------------------------
    SHELLCHECK_PATH = "shellcheck";
    SHFMT_PATH = "shfmt";
    BASH_IDE_LOG_LEVEL = "info";

    # --- YAML/JSON ----------------------------------------------------------
    YAMLLINT_CONFIG_FILE = "${config.xdg.configHome}/yamllint/config";

    # --- TypeScript/JavaScript Tooling -------------------------------------
    TAILWIND_MODE = "watch"; # JIT compilation for development
    VITEST_MODE = "run"; # Default test runner mode
  };
}
