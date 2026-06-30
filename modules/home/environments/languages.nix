# Title         : languages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/languages.nix
# ----------------------------------------------------------------------------
# Programming language toolchains and environments
{
  config,
  lib,
  pkgs,
  ...
}: let
  toolchainEnv = import ../../common/toolchain-env.nix {
    inherit lib pkgs;
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
    xdgDataHome = config.xdg.dataHome;
  };
in {
  home.sessionVariables =
    toolchainEnv.scientificSessionEnv
    // {
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
