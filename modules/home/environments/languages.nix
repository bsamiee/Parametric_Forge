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
      # --- [LUA]
      LUAROCKS_CONFIG = "${config.xdg.configHome}/luarocks/config.lua";
      LUAROCKS_TREE = "${config.xdg.dataHome}/luarocks";

      # --- [SHELL_LINTERS]
      SHELLCHECK_PATH = "shellcheck";
      SHFMT_PATH = "shfmt";
      BASH_IDE_LOG_LEVEL = "info";

      # --- [YAML_JSON]
      YAMLLINT_CONFIG_FILE = "${config.xdg.configHome}/yamllint/config";

      # --- [DATABASE_FRONT_DOORS]
      # Harlequin discovers config through platformdirs (~/Library on darwin); pin it to XDG.
      HARLEQUIN_CONFIG_PATH = "${config.xdg.configHome}/harlequin/config.toml";
      # VisiData's vendored appdirs resolves darwin config to ~/Library/Preferences; VD_CONFIG pins the generated config, VD_DIR keeps cmdlog/macros in XDG state.
      VD_CONFIG = "${config.xdg.configHome}/visidata/config.py";
      VD_DIR = "${config.xdg.stateHome}/visidata";

      # --- [TYPESCRIPT_JAVASCRIPT_TOOLING]
      TAILWIND_MODE = "watch"; # JIT compilation for development
      VITEST_MODE = "run"; # Default test runner mode

      # --- [NODE_PNPM_RAIL]
      # pnpm is the sole package-manager verb on PATH; npm_config_* rows contain any vendored npm run under XDG,
      # COREPACK_* rows neutralize transitive corepack calls (network off, strict pins, XDG cache).
      PNPM_HOME = "${config.xdg.dataHome}/pnpm";
      npm_config_cache = "${config.xdg.cacheHome}/npm";
      npm_config_userconfig = "${config.xdg.configHome}/npm/npmrc";
      npm_config_globalconfig = "${config.xdg.configHome}/npm/global-npmrc";
      npm_config_prefix = "${config.xdg.dataHome}/npm-global";
      COREPACK_HOME = "${config.xdg.cacheHome}/node/corepack";
      COREPACK_ENABLE_STRICT = "1";
      COREPACK_ENABLE_NETWORK = "0";

      # --- [HEADLESS_RENDER_PUPPETEER_PLAYWRIGHT_MERMAID]
      # Shared Nix Chrome-for-Testing pin (owned by toolchain-env) so mmdc/puppeteer and the mermaid validator
      # never launch the real Chrome.app or an unstable downloaded shell.
      PUPPETEER_EXECUTABLE_PATH = toolchainEnv.puppeteerExecutablePath;
      # One machine-wide browsers path: playwright/patchright default to ~/Library/Caches/ms-playwright, outside XDG; every repo shares this pin.
      PLAYWRIGHT_BROWSERS_PATH = "${config.xdg.cacheHome}/ms-playwright";
    };
}
