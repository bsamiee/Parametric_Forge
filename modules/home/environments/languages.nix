# Title         : languages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/languages.nix
# ----------------------------------------------------------------------------
# Programming language toolchains and environments

{ config, ... }:

{
  home.sessionVariables = {
    # --- Python -------------------------------------------------------------
    PYTEST_CACHE_DIR = "${config.xdg.cacheHome}/pytest";
    RUFF_CACHE_DIR = "${config.xdg.cacheHome}/ruff";
    MYPY_CACHE_DIR = "${config.xdg.cacheHome}/mypy";
    PYLINTHOME = "${config.xdg.cacheHome}/pylint";
    NOX_CACHE_DIR = "${config.xdg.cacheHome}/nox";
    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
    PYTHONDONTWRITEBYTECODE = "1";

    # --- Lua ----------------------------------------------------------------
    LUAROCKS_CONFIG = "${config.xdg.configHome}/luarocks/config.lua";
    LUAROCKS_TREE = "${config.xdg.dataHome}/luarocks";

    # --- Shell Linters ------------------------------------------------------
    SHELLCHECK_PATH = "shellcheck";
    SHFMT_PATH = "shfmt";
    BASH_IDE_LOG_LEVEL = "info";

    # --- YAML/JSON ----------------------------------------------------------
    YAMLLINT_CONFIG_FILE = "${config.xdg.configHome}/yamllint/config";

    # --- Node/JavaScript ----------------------------------------------------
    # Node.js runtime
    NODE_ENV = "production";                      # Production by default - critical for performance
    NODE_OPTIONS = "--max-old-space-size=4096";   # Memory management
    NODE_NO_WARNINGS = "1";                       # Reduce noise from warnings
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/repl_history";
    NODE_V8_COVERAGE = "${config.xdg.cacheHome}/node/coverage";
    # npm configuration
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    # pnpm paths
    PNPM_HOME = "${config.xdg.dataHome}/pnpm";
    npm_config_store_dir = "${config.xdg.dataHome}/pnpm/store";
    npm_config_cache_dir = "${config.xdg.cacheHome}/pnpm";
    npm_config_global_dir = "${config.xdg.dataHome}/pnpm/global";
    npm_config_global_bin_dir = "${config.xdg.dataHome}/pnpm";
    npm_config_state_dir = "${config.xdg.stateHome}/pnpm";
    # fnm (Fast Node Manager)
    FNM_DIR = "${config.xdg.dataHome}/fnm";
    FNM_COREPACK_ENABLED = "true";
    FNM_NODE_DIST_MIRROR = "https://nodejs.org/dist";
    FNM_RESOLVE_ENGINES = "true";
    FNM_LOGLEVEL = "info";                        # Options: quiet, error, info
  };
}
