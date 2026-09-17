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

      # --- [DATABASE_FRONT_DOORS]
      # Harlequin discovers config through platformdirs (~/Library on darwin); pin it to XDG.
      HARLEQUIN_CONFIG_PATH = "${config.xdg.configHome}/harlequin/config.toml";
      # VisiData's vendored appdirs resolves darwin config to ~/Library/Preferences; VD_CONFIG pins the generated config, VD_DIR keeps cmdlog/macros in XDG state.
      VD_CONFIG = "${config.xdg.configHome}/visidata/config.py";
      VD_DIR = "${config.xdg.stateHome}/visidata";

      # --- [NODE_PNPM_RAIL]
      # A project's mise.toml owns node and pnpm (PNPM_HOME is a cross-surface row of modules/common/toolchain-env.nix); npm_config_* rows
      # contain any vendored npm run under XDG, COREPACK_* rows neutralize transitive corepack calls (network off, strict pins, XDG cache).
      npm_config_cache = "${config.xdg.cacheHome}/npm";
      npm_config_userconfig = "${config.xdg.configHome}/npm/npmrc";
      npm_config_globalconfig = "${config.xdg.configHome}/npm/global-npmrc";
      npm_config_prefix = "${config.xdg.dataHome}/npm-global";
      COREPACK_HOME = "${config.xdg.cacheHome}/node/corepack";
      COREPACK_ENABLE_STRICT = "1";
      COREPACK_ENABLE_NETWORK = "0";

      # --- [HEADLESS_RENDER_PUPPETEER_PLAYWRIGHT_MERMAID]
      # PUPPETEER_EXECUTABLE_PATH is a cross-surface row of modules/common/toolchain-env.nix, which owns the headless shell pin.
      # PLAYWRIGHT_BROWSERS_PATH is never a machine-wide row: each project's `mise.toml` owns its own browser build, and the
      # activated shell applies it inside that tree.
    };
}
