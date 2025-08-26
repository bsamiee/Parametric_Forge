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
      mkdir -pm 755 "${config.xdg.configHome}/lazydocker"
      mkdir -pm 755 "${config.xdg.configHome}/dive"
      mkdir -pm 755 "${config.xdg.configHome}/hadolint"
      mkdir -pm 755 "${config.xdg.configHome}/wezterm"
      mkdir -pm 755 "${config.xdg.configHome}/xh"
      mkdir -pm 755 "${config.xdg.configHome}/shellcheck"
      # Shell tools (managed by home-manager or have configs)
      mkdir -pm 755 "${config.xdg.configHome}/broot" # Managed by home-manager
      mkdir -pm 755 "${config.xdg.configHome}/starship" # Has config file
      mkdir -pm 755 "${config.xdg.configHome}/mcfly" # Managed by home-manager
      mkdir -pm 755 "${config.xdg.configHome}/bottom" # Managed by home-manager
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
      mkdir -pm 755 "${config.xdg.configHome}/pytest"
      # Lua
      mkdir -pm 755 "${config.xdg.configHome}/luarocks"
      mkdir -pm 755 "${config.xdg.configHome}/lua-language-server"
      # Formatting tools (only those that support XDG)
      mkdir -pm 755 "${config.xdg.configHome}/taplo"
      mkdir -pm 755 "${config.xdg.configHome}/yamllint"
      # Java
      mkdir -pm 755 "${config.xdg.configHome}/java"
      # Build & Task Automation
      mkdir -pm 755 "${config.xdg.configHome}/just"
      mkdir -pm 755 "${config.xdg.configHome}/pre-commit"
      # SQL Tools
      mkdir -pm 755 "${config.xdg.configHome}/sqlfluff"
      mkdir -pm 755 "${config.xdg.configHome}/pgformatter"
      # Secret Management
      mkdir -pm 755 "${config.xdg.configHome}/vault"
      mkdir -pm 755 "${config.xdg.configHome}/pass"
      mkdir -pm 755 "${config.xdg.configHome}/gopass"
      # Backup & Sync
      mkdir -pm 755 "${config.xdg.configHome}/restic"
      mkdir -pm 755 "${config.xdg.configHome}/rclone"
      # Data Processing
      mkdir -pm 755 "${config.xdg.configHome}/fx"
      mkdir -pm 755 "${config.xdg.configHome}/jless"
      # Utilities
      mkdir -pm 755 "${config.xdg.configHome}/tldr"
      mkdir -pm 755 "${config.xdg.configHome}/watchexec"
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
      # NOTE: gradle not installed - removed directory
      mkdir -pm 755 "${config.xdg.dataHome}/docker-machine"
      mkdir -pm 755 "${config.xdg.dataHome}/docker/certs"
      mkdir -pm 755 "${config.xdg.dataHome}/colima"
      mkdir -pm 755 "${config.xdg.dataHome}/podman"
      # NOTE: gnupg not installed - removed directory
      # Build & Task Automation
      mkdir -pm 755 "${config.xdg.dataHome}/pre-commit"
      # Secret Management
      mkdir -pm 755 "${config.xdg.dataHome}/pass"
      mkdir -pm 755 "${config.xdg.dataHome}/gopass"
      mkdir -pm 755 "${config.xdg.dataHome}/vault"
      # Shell tools data
      mkdir -pm 755 "${config.xdg.dataHome}/broot"
      mkdir -pm 755 "${config.xdg.dataHome}/zoxide"
      mkdir -pm 755 "${config.xdg.dataHome}/mcfly"
      # --- State Directories -----------------------------------------------
      mkdir -pm 755 "${config.xdg.stateHome}/nix"
      mkdir -pm 755 "${config.xdg.stateHome}/logs"
      mkdir -pm 755 "${config.xdg.stateHome}/bash"
      mkdir -pm 755 "${config.xdg.stateHome}/zsh"
      mkdir -pm 755 "${config.xdg.cacheHome}/zsh"
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
      mkdir -pm 755 "${config.xdg.cacheHome}/pytest"
      mkdir -pm 755 "${config.xdg.cacheHome}/cargo"
      mkdir -pm 755 "${config.xdg.cacheHome}/rust-analyzer"
      mkdir -pm 755 "${config.xdg.cacheHome}/sccache"
      mkdir -pm 755 "${config.xdg.cacheHome}/shellcheck"
      mkdir -pm 755 "${config.xdg.cacheHome}/nix-index"
      # Container runtime caches
      mkdir -pm 755 "${config.xdg.cacheHome}/docker"
      mkdir -pm 755 "${config.xdg.cacheHome}/colima"
      mkdir -pm 755 "${config.xdg.cacheHome}/podman"
      mkdir -pm 755 "${config.xdg.cacheHome}/lazydocker"
      mkdir -pm 755 "${config.xdg.cacheHome}/dive"
      mkdir -pm 755 "${config.xdg.cacheHome}/buildkit"
      # Shell tools caches
      mkdir -pm 755 "${config.xdg.cacheHome}/bat"
      mkdir -pm 755 "${config.xdg.cacheHome}/direnv"
      mkdir -pm 755 "${config.xdg.cacheHome}/fd"
      # Lua tools caches
      mkdir -pm 755 "${config.xdg.cacheHome}/lua-language-server"
      # Build & Task Automation caches
      mkdir -pm 755 "${config.xdg.cacheHome}/pre-commit"
      # SQL Tools caches  
      mkdir -pm 755 "${config.xdg.cacheHome}/sqlfluff"
      # Secret Management caches
      mkdir -pm 755 "${config.xdg.cacheHome}/vault"
      # Backup & Sync caches
      mkdir -pm 755 "${config.xdg.cacheHome}/restic"
      mkdir -pm 755 "${config.xdg.cacheHome}/rclone"
      # Utilities caches
      mkdir -pm 755 "${config.xdg.cacheHome}/tldr"
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
