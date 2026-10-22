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
      # --- [NODE_PNPM_RAIL]
      # Project mise.toml files own node and pnpm; npm_config_* rows configure bundled npm and npx, and pnpm reads the npm_config_userconfig
      # file as well. npm_config_cache is a cross-surface row of modules/common/toolchain-env.nix.
      npm_config_userconfig = "${config.xdg.configHome}/npm/npmrc";
      npm_config_globalconfig = "${config.xdg.configHome}/npm/global-npmrc";

      # --- [HEADLESS_RENDER_PLAYWRIGHT]
      # PLAYWRIGHT_BROWSERS_PATH is never a machine-wide row: each project's `mise.toml` owns its own browser build, and the
      # activated shell applies it inside that tree.
    };
}
