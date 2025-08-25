# Title         : 01.home/xdg.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/xdg.nix
# ----------------------------------------------------------------------------
# Manages the XDG Base Directory specification for the user.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # --- XDG Configuration ----------------------------------------------------
  xdg = {
    enable = true; # Enable the XDG module in home-manager

    # --- Standard User Directories ------------------------------------------
    # userDirs only works on Linux, not macOS
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
  };
  # --- XDG Runtime Directory ------------------------------------------------
  # Note: XDG_RUNTIME_DIR is set at system level in 00.system/environment.nix
  # macOS: ~/Library/Caches/TemporaryItems
  # Linux: /run/user/$UID (default)

  # --- Home Activation Scripts ----------------------------------------------
  home.activation = {
    # --- Create XDG Directory Structure -------------------------------------
    createXdgDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "[Parametric Forge] Creating XDG directory structure..."

      # Core XDG directories (created by home-manager but ensure they exist)
      mkdir -pm 755 "${config.xdg.configHome}"
      mkdir -pm 755 "${config.xdg.dataHome}"
      mkdir -pm 755 "${config.xdg.stateHome}"
      mkdir -pm 755 "${config.xdg.cacheHome}"
      # --- Configuration Directories ---------------------------------------
      mkdir -pm 755 "${config.xdg.configHome}/fontconfig"
      mkdir -pm 755 "${config.xdg.configHome}/git"
      mkdir -pm 755 "${config.xdg.configHome}/nix"
      mkdir -pm 755 "${config.xdg.configHome}/nil"
      mkdir -pm 755 "${config.xdg.configHome}/op"
      mkdir -pm 755 "${config.xdg.configHome}/nvim"
      mkdir -pm 755 "${config.xdg.configHome}/npm"
      mkdir -pm 755 "${config.xdg.configHome}/docker"
      mkdir -pm 755 "${config.xdg.configHome}/containers"
      mkdir -pm 755 "${config.xdg.configHome}/gh"
      mkdir -pm 755 "${config.xdg.configHome}/lazygit"
      mkdir -pm 755 "${config.xdg.configHome}/wezterm"
      mkdir -pm 755 "${config.xdg.configHome}/xh"
      mkdir -pm 755 "${config.xdg.configHome}/shellcheck"
      mkdir -pm 755 "${config.xdg.configHome}/marksman"
      mkdir -pm 755 "${config.xdg.configHome}/rust-analyzer"
      mkdir -pm 755 "${config.xdg.configHome}/clippy"
      mkdir -pm 755 "${config.xdg.configHome}/cargo"
      # Python tools
      mkdir -pm 755 "${config.xdg.configHome}/python"
      mkdir -pm 755 "${config.xdg.configHome}/pypoetry"
      mkdir -pm 755 "${config.xdg.configHome}/basedpyright"
      mkdir -pm 755 "${config.xdg.configHome}/ruff"
      mkdir -pm 755 "${config.xdg.configHome}/mypy"
      # JavaScript/TypeScript
      mkdir -pm 755 "${config.xdg.configHome}/typescript"
      mkdir -pm 755 "${config.xdg.configHome}/eslint"
      # Lua
      mkdir -pm 755 "${config.xdg.configHome}/luarocks"
      # Formatting tools (only those that support XDG)
      mkdir -pm 755 "${config.xdg.configHome}/taplo"
      mkdir -pm 755 "${config.xdg.configHome}/yamllint"
      # Java
      mkdir -pm 755 "${config.xdg.configHome}/java"
      # --- Data Directories ------------------------------------------------
      mkdir -pm 755 "${config.xdg.dataHome}/applications"
      mkdir -pm 755 "${config.xdg.dataHome}/fonts"
      mkdir -pm 755 "${config.xdg.dataHome}/icons"
      mkdir -pm 755 "${config.xdg.dataHome}/backups"
      mkdir -pm 755 "${config.xdg.dataHome}/nix-defexpr"
      # Development tools
      mkdir -pm 755 "${config.xdg.dataHome}/cargo"
      mkdir -pm 755 "${config.xdg.dataHome}/rustup"
      mkdir -pm 755 "${config.xdg.dataHome}/go"
      mkdir -pm 755 "${config.xdg.dataHome}/npm"
      mkdir -pm 755 "${config.xdg.dataHome}/pipx"
      mkdir -pm 755 "${config.xdg.dataHome}/gradle"
      mkdir -pm 755 "${config.xdg.dataHome}/docker-machine"
      mkdir -pm 755 "${config.xdg.dataHome}/colima"
      mkdir -pm 700 "${config.xdg.dataHome}/gnupg"
      # --- State Directories -----------------------------------------------
      mkdir -pm 755 "${config.xdg.stateHome}/nix"
      mkdir -pm 755 "${config.xdg.stateHome}/logs"
      mkdir -pm 755 "${config.xdg.stateHome}/bash"
      mkdir -pm 755 "${config.xdg.stateHome}/zsh"
      mkdir -pm 755 "${config.xdg.stateHome}/less"
      mkdir -pm 755 "${config.xdg.stateHome}/python"
      mkdir -pm 755 "${config.xdg.stateHome}/sqlite"
      mkdir -pm 755 "${config.xdg.stateHome}/wezterm"  # For daemon socket and logs
      # --- Cache Directories -----------------------------------------------
      mkdir -pm 755 "${config.xdg.cacheHome}/nix"
      mkdir -pm 755 "${config.xdg.cacheHome}/op"
      mkdir -pm 755 "${config.xdg.cacheHome}/ssh"
      mkdir -pm 755 "${config.xdg.cacheHome}/claude"
      mkdir -pm 755 "${config.xdg.cacheHome}/claude/logs"
      mkdir -pm 755 "${config.xdg.cacheHome}/fontconfig"
      mkdir -pm 755 "${config.xdg.cacheHome}/npm"
      mkdir -pm 755 "${config.xdg.cacheHome}/npm-tmp"
      mkdir -pm 755 "${config.xdg.cacheHome}/pip"
      mkdir -pm 755 "${config.xdg.cacheHome}/pypoetry"
      mkdir -pm 755 "${config.xdg.cacheHome}/pylint"
      mkdir -pm 755 "${config.xdg.cacheHome}/ruff"
      mkdir -pm 755 "${config.xdg.cacheHome}/basedpyright"
      mkdir -pm 755 "${config.xdg.cacheHome}/mypy"
      mkdir -pm 755 "${config.xdg.cacheHome}/uv"
      mkdir -pm 755 "${config.xdg.cacheHome}/cargo"
      mkdir -pm 755 "${config.xdg.cacheHome}/rust-analyzer"
      mkdir -pm 755 "${config.xdg.cacheHome}/sccache"
      mkdir -pm 755 "${config.xdg.cacheHome}/shellcheck"
      mkdir -pm 755 "${config.xdg.cacheHome}/nix-index"
      # Container runtime caches
      mkdir -pm 755 "${config.xdg.cacheHome}/docker"
      mkdir -pm 755 "${config.xdg.cacheHome}/colima"
      mkdir -pm 755 "${config.xdg.cacheHome}/podman"
      # --- Non-XDG Directories ---------------------------------------------
      mkdir -pm 700 "${config.home.homeDirectory}/.ssh"
      mkdir -pm 700 "${config.home.homeDirectory}/.ssh/sockets"
      mkdir -pm 755 "${config.home.homeDirectory}/.local/bin"
      mkdir -pm 755 "${config.home.homeDirectory}/.local/lib"
      mkdir -pm 755 "${config.home.homeDirectory}/.local/lib/sqlean"
      mkdir -pm 755 "${config.home.homeDirectory}/.local/lib/sqlite-vec"
      mkdir -pm 755 "${config.home.homeDirectory}/bin"

      echo "  ✓ XDG directory structure created"
    '';
  };
}
