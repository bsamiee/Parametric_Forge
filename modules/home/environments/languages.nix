# Title         : languages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/languages.nix
# ----------------------------------------------------------------------------
# Programming language toolchains and environments
{
  config,
  forgeToolchainEnvFor,
  ...
}: let
  toolchainEnv = forgeToolchainEnvFor {
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
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

      # --- Headless Render (Puppeteer/Mermaid) -------------------------------
      # Shared Nix Chrome-for-Testing pin (owned by toolchain-env) so mmdc/puppeteer and the mermaid validator never launch the real Chrome.app or an unstable downloaded shell.
      PUPPETEER_EXECUTABLE_PATH = toolchainEnv.puppeteerExecutablePath;
    };
}
