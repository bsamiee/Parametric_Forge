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
    WEZTERM_CONFIG_DIR = "${config.xdg.configHome}/wezterm";
    WEZTERM_RUNTIME_DIR = "${config.xdg.stateHome}/wezterm";
    WEZTERM_LOG_DIR = "${config.xdg.stateHome}/wezterm";

    # --- Zellij --------------------------------------------------------------
    ZELLIJ_CONFIG_DIR = "${config.xdg.configHome}/zellij";
    ZELLIJ_AUTO_ATTACH = "false"; # Handled in WezTerm config for auto-loading Zellij
    ZELLIJ_AUTO_EXIT = "false"; # Handled in WezTerm config for auto-loading Zellij

    # --- Serpl ---------------------------------------------------------------
    SERPL_CONFIG = "${config.xdg.configHome}/serpl";
    SERPL_DATA = "${config.xdg.dataHome}/serpl";
    SERPL_LOGLEVEL = "info";

    # --- 1Password -----------------------------------------------------------
    OP_BIOMETRIC_UNLOCK_ENABLED = "true";
    OP_ENV_TEMPLATE = "${config.xdg.configHome}/op/env.template";
    OP_ENV_CACHE = "${config.xdg.cacheHome}/op/env.cache";
    OP_CONFIG_DIR = "${config.xdg.configHome}/op";
    OP_CACHE = "true";  # Enable caching for better performance

    # --- Claude --------------------------------------------------------------
    CLAUDE_CACHE_DIR = "${config.xdg.cacheHome}/claude";

    # --- Karabiner/Goku ------------------------------------------------------
    GOKU_EDN_CONFIG_FILE = "${config.xdg.configHome}/karabiner/karabiner.edn";
  };
}
