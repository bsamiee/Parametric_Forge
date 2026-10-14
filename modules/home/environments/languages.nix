# Title         : languages.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/languages.nix
# ----------------------------------------------------------------------------
# Programming language toolchains and environments
{
  config,
  toolchainEnvFor,
  ...
}: let
  toolchainEnv = toolchainEnvFor {
    home = config.home.homeDirectory;
    username = config.home.username;
    xdgCacheHome = config.xdg.cacheHome;
  };
in {
  home.sessionVariables =
    toolchainEnv.scientificSessionEnv
    // {
      # --- [DATABASE_FRONT_DOORS]
      # Harlequin discovers config through platformdirs (~/Library on darwin); pin it to XDG.
      HARLEQUIN_CONFIG_PATH = "${config.xdg.configHome}/harlequin/config.toml";
      # VisiData's vendored appdirs resolves darwin config to ~/Library/Preferences; VD_CONFIG pins the generated config, VD_DIR keeps cmdlog/macros in XDG state.
      VD_CONFIG = "${config.xdg.configHome}/visidata/config.py";
      VD_DIR = "${config.xdg.stateHome}/visidata";

      # --- [NODE_PNPM_RAIL]
      # Project mise.toml files own node and pnpm, PNPM_HOME is a cross-surface row of modules/common/toolchain-env.nix
      # npm_config_* rows configure bundled npm and npx, and pnpm reads the npm_config_userconfig file as well
      # npm_config_cache is a cross-surface row of modules/common/toolchain-env.nix
      npm_config_userconfig = "${config.xdg.configHome}/npm/npmrc";
      npm_config_globalconfig = "${config.xdg.configHome}/npm/global-npmrc";
      npm_config_prefix = "${config.xdg.dataHome}/npm-global";

      # --- [HEADLESS_RENDER_PUPPETEER_PLAYWRIGHT_MERMAID]
      # PUPPETEER_EXECUTABLE_PATH is a cross-surface row of modules/common/toolchain-env.nix, which owns the headless shell pin.
      # PLAYWRIGHT_BROWSERS_PATH is never a machine-wide row: each project's `mise.toml` owns its own browser build, and the
      # activated shell applies it inside that tree.
    };
}
