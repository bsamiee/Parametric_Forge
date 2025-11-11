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
        GH_TOKEN="op://Tokens/Github Token/token"
        GITHUB_CLASSIC_TOKEN="op://Tokens/Github Classic Token/token"
        PERPLEXITY_API_KEY="op://Tokens/Perplexity Sonar API Key/token"
        CACHIX_AUTH_TOKEN="op://Tokens/Cachix Auth Token - Parametric Forge/token"
        TAVILY_API_KEY="op://Tokens/Tavily Auth Token/token"
        EXA_API_KEY="op://Tokens/Exa API Key/token"
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

  home.activation.ensureXdgMediaDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    install -d -m 700 "${config.xdg.configHome}/ssh"
    install -d -m 700 "${config.xdg.stateHome}/ssh"
    install -d -m 700 "${config.xdg.configHome}/transmission-daemon"

    if [ ! -f "${config.xdg.configHome}/ssh/known_hosts" ]; then
      touch "${config.xdg.configHome}/ssh/known_hosts"
      chmod 600 "${config.xdg.configHome}/ssh/known_hosts"
    fi

    mkdir -p "${config.xdg.stateHome}/ffmpeg"
    mkdir -p "${config.xdg.cacheHome}/ImageMagick"
    mkdir -p "${config.xdg.configHome}/ImageMagick"
    mkdir -p "${config.xdg.cacheHome}/mpv"
    mkdir -p "${config.xdg.dataHome}/mpv/watch_later"
    mkdir -p "${config.home.homeDirectory}/Pictures/mpv"
    mkdir -p "${config.xdg.configHome}/pandoc"
    mkdir -p "${config.xdg.dataHome}/pandoc"
    mkdir -p "${config.xdg.cacheHome}/ocrmypdf"
  '';
}
