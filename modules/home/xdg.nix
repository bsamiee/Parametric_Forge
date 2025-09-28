# Title         : xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg.nix
# ----------------------------------------------------------------------------
# XDG base directory specification and structure

{ config, lib, pkgs, ... }:

{
  # --- Core XDG configuration -----------------------------------------------
  xdg = {
    enable = true;

    # --- Linux-specific user directories ------------------------------------
    userDirs = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      createDirectories = true;
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      desktop = "${config.home.homeDirectory}/Desktop";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
    };

    # --- Config directories (XDG_CONFIG_HOME) -------------------------------
    configFile = {
      # 1Password secret template
      "op/env.template".text = ''
        # 1Password Secret References (auto-generated)
        GITHUB_TOKEN="op://Tokens/Github Token/token"
        GITHUB_CLASSIC_TOKEN="op://Tokens/Classic Github Token/token"
        PERPLEXITY_API_KEY="op://Tokens/Perplexity API Key/api key"
        CACHIX_AUTH_TOKEN="op://Tokens/Cachix Token/token"
        TAVILY_API_KEY="op://Tokens/Tavily API Key/api key"
        EXA_API_KEY="op://Tokens/Exa API Key/api key"
      '';
    };

    # --- Data directories (XDG_DATA_HOME) -----------------------------------
    dataFile = {
      # Placeholder comment
    } // lib.optionalAttrs pkgs.stdenv.isLinux {
      # Linux desktop integration
      "applications/.keep".text = "";
      "icons/.keep".text = "";
      "Trash/files/.keep".text = "";
      "Trash/info/.keep".text = "";
    };

    # --- Cache directories (XDG_CACHE_HOME) ---------------------------------
    cacheFile = {
      # Placeholder comment
    };

    # --- State directories (XDG_STATE_HOME) ---------------------------------
    stateFile = {
      # Placeholder comment
    };
  };

  # --- Non-XDG home directories ---------------------------------------------
  home.activation.createHomeDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # SSH with proper permissions
    mkdir -pm 700 "${config.home.homeDirectory}/.ssh"
    mkdir -pm 700 "${config.home.homeDirectory}/.ssh/sockets"

    # Local binaries
    mkdir -pm 755 "${config.home.homeDirectory}/.local/bin"
    mkdir -pm 755 "${config.home.homeDirectory}/bin"
  '';
}
