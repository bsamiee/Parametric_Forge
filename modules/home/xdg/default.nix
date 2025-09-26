# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg/default.nix
# ----------------------------------------------------------------------------
# XDG base directory specification and structure

{ config, lib, pkgs, ... }:

{
  imports = [
    ./config_xdg.nix   # XDG_CONFIG_HOME directories
    ./data_xdg.nix     # XDG_DATA_HOME directories
    ./cache_xdg.nix    # XDG_CACHE_HOME directories
    ./state_xdg.nix    # XDG_STATE_HOME directories
    ./home_xdg.nix     # Non-XDG home directories
    ./linux_xdg.nix    # Linux-specific userDirs
  ];

  # --- Core XDG configuration -----------------------------------------------
  xdg = {
    enable = true;
    # Paths are auto-set by home-manager:
    # configHome = "${config.home.homeDirectory}/.config";
    # dataHome = "${config.home.homeDirectory}/.local/share";
    # cacheHome = "${config.home.homeDirectory}/.cache";
    # stateHome = "${config.home.homeDirectory}/.local/state";
  };
}
