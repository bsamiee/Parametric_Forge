# Title         : applications.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/applications.nix
# ----------------------------------------------------------------------------
# User application environment variables
{config, ...}: {
  home.sessionVariables = {
    # --- [WEZTERM]
    WEZTERM_CONFIG_DIR = "${config.xdg.configHome}/wezterm";
    WEZTERM_RUNTIME_DIR = "${config.xdg.stateHome}/wezterm";
    WEZTERM_LOG_DIR = "${config.xdg.stateHome}/wezterm";

    # --- [ZELLIJ]
    ZELLIJ_CONFIG_DIR = "${config.xdg.configHome}/zellij";
    ZELLIJ_AUTO_ATTACH = "false"; # Handled in WezTerm config for auto-loading Zellij
    ZELLIJ_AUTO_EXIT = "false"; # Handled in WezTerm config for auto-loading Zellij
    ZELLIJ_DEFAULT_LAYOUT = "default";

    # --- [YAZI]
    YAZI_CONFIG_HOME = "${config.xdg.configHome}/yazi";

    # --- [NEOVIM]
    # Editor RPC rail uses native `nvim --listen`/`--server`; sockets live under
    # the private runtime root (XDG runtime dir, else per-user TMPDIR) at
    # forge-edit/<session>/ per the integration script registry.

    # --- [SERPL]
    SERPL_CONFIG = "${config.xdg.configHome}/serpl";
    SERPL_DATA = "${config.xdg.dataHome}/serpl";
    SERPL_LOGLEVEL = "info";
  };
}
