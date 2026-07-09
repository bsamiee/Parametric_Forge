# Title         : xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/xdg.nix
# ----------------------------------------------------------------------------
# XDG base directory specification and structure
{
  config,
  lib,
  pkgs,
  ...
}: {
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

    # --- Linux desktop integration (XDG_DATA_HOME) ---------------------------
    dataFile = lib.mkIf pkgs.stdenv.isLinux {
      "applications/.keep".text = "";
      "icons/.keep".text = "";
      "Trash/files/.keep".text = "";
      "Trash/info/.keep".text = "";
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
    mkdir -p \
      "${config.xdg.stateHome}/ffmpeg" \
      "${config.xdg.cacheHome}/ImageMagick" \
      "${config.xdg.configHome}/ImageMagick" \
      "${config.xdg.cacheHome}/mpv" \
      "${config.xdg.dataHome}/mpv/watch_later" \
      "${config.home.homeDirectory}/Pictures/mpv" \
      "${config.xdg.configHome}/pandoc" \
      "${config.xdg.dataHome}/pandoc"
  '';
}
