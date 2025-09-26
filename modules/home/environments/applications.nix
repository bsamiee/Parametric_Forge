# Title         : applications.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/applications.nix
# ----------------------------------------------------------------------------
# User application environment variables

{ config, ... }:

{
  home.sessionVariables = {
    # --- WezTerm -------------------------------------------------------------
    WEZTERM_UTILS_BIN = "${config.home.profileDirectory}/bin/wezterm-utils.sh";
    WEZTERM_CONFIG_DIR = "${config.xdg.configHome}/wezterm";
    WEZTERM_RUNTIME_DIR = "${config.xdg.stateHome}/wezterm";
    WEZTERM_LOG_DIR = "${config.xdg.stateHome}/wezterm";

    # --- Starship ------------------------------------------------------------
    STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

    # --- 1Password -----------------------------------------------------------
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
    OP_ENV_TEMPLATE = "${config.xdg.configHome}/op/env.template";
    OP_ENV_CACHE = "${config.xdg.cacheHome}/op/env.cache";

    # --- Claude --------------------------------------------------------------
    CLAUDE_CACHE_DIR = "${config.xdg.cacheHome}/claude";

    # --- Karabiner/Goku ------------------------------------------------------
    GOKU_EDN_CONFIG_FILE = "${config.xdg.configHome}/karabiner/karabiner.edn";
  };
}
