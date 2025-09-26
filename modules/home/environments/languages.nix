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
    # --- Python --------------------------------------------------------------
    MYPY_CONFIG_FILE = "${config.xdg.configHome}/mypy/mypy.ini";
    PYTHONHISTORY = "${config.xdg.stateHome}/python/history";
    PYTEST_CACHE_DIR = "${config.xdg.cacheHome}/pytest";
    RUFF_CACHE_DIR = "${config.xdg.cacheHome}/ruff";
    MYPY_CACHE_DIR = "${config.xdg.cacheHome}/mypy";
    PYLINTHOME = "${config.xdg.cacheHome}/pylint";
    NOX_CACHE_DIR = "${config.xdg.cacheHome}/nox";
    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
    PYTHONDONTWRITEBYTECODE = "1";

    # --- Node/JavaScript -----------------------------------------------------
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    NODE_REPL_HISTORY = "${config.xdg.dataHome}/node_repl_history";
    PNPM_HOME = "${config.xdg.dataHome}/pnpm";

    # --- Lua -----------------------------------------------------------------
    LUAROCKS_CONFIG = "${config.xdg.configHome}/luarocks/config.lua";
    LUAROCKS_TREE = "${config.xdg.dataHome}/luarocks";

    # --- Shell Linters -------------------------------------------------------
    SHELLCHECK_PATH = "shellcheck";
    SHFMT_PATH = "shfmt";
    BASH_IDE_LOG_LEVEL = "info";

    # --- YAML/JSON -----------------------------------------------------------
    YAMLLINT_CONFIG_FILE = "${config.xdg.configHome}/yamllint/config";
  };
}
