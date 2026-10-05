# Title         : applications.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/applications.nix
# ----------------------------------------------------------------------------
# User application environment variables
{config, ...}: {
  home.sessionVariables = {
    # WezTerm and Zellij carry no row: both read their $XDG_CONFIG_HOME directory, WezTerm keeps its runtime and logs under ~/.local/share/wezterm.

    # --- [YAZI]
    YAZI_CONFIG_HOME = "${config.xdg.configHome}/yazi";

    # --- [NEOVIM]
    # Editor RPC rail: `nvim --listen`/`--server`; sockets under private runtime root (XDG runtime dir, else per-user TMPDIR) at nvim-edit/<session>/.

    # --- [SERPL]
    SERPL_CONFIG = "${config.xdg.configHome}/serpl";
    SERPL_DATA = "${config.xdg.dataHome}/serpl";
    SERPL_LOGLEVEL = "info";
  };
}
