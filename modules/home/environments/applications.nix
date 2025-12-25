# Title         : applications.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/applications.nix
# ----------------------------------------------------------------------------
# User application environment variables
{config, ...}: {
  home.sessionVariables = {
    # --- WezTerm ------------------------------------------------------------
    WEZTERM_CONFIG_DIR = "${config.xdg.configHome}/wezterm";
    WEZTERM_RUNTIME_DIR = "${config.xdg.stateHome}/wezterm";
    WEZTERM_LOG_DIR = "${config.xdg.stateHome}/wezterm";
    WEZTERM_UTILS_BIN = "${config.xdg.configHome}/wezterm/bin/wezterm-utils.sh";

    # --- Zellij -------------------------------------------------------------
    ZELLIJ_CONFIG_DIR = "${config.xdg.configHome}/zellij";
    ZELLIJ_AUTO_ATTACH = "false"; # Handled in WezTerm config for auto-loading Zellij
    ZELLIJ_AUTO_EXIT = "false"; # Handled in WezTerm config for auto-loading Zellij
    ZELLIJ_DEFAULT_LAYOUT = "default";

    # --- Yazi ---------------------------------------------------------------
    YAZI_CONFIG_HOME = "${config.xdg.configHome}/yazi";

    # --- Neovim -------------------------------------------------------------
    # Note: Modern Neovim uses --listen flag instead of NVIM_LISTEN_ADDRESS (obsolete)
    # Socket path format: $XDG_RUNTIME_DIR/nvim-$ZELLIJ_SESSION_NAME.sock
    # Usage: nvim --listen "$socket_path" (see integration scripts for implementation)

    # --- Serpl --------------------------------------------------------------
    SERPL_CONFIG = "${config.xdg.configHome}/serpl";
    SERPL_DATA = "${config.xdg.dataHome}/serpl";
    SERPL_LOGLEVEL = "info";

    # --- Claude -------------------------------------------------------------
    CLAUDE_CACHE_DIR = "${config.xdg.cacheHome}/claude";
  };
}
