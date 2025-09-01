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
  # Note: XDG_RUNTIME_DIR uses macOS native temporary directory structure
  # macOS: $(getconf DARWIN_USER_TEMP_DIR) - typically /var/folders/...
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
      mkdir -pm 755 "${config.xdg.configHome}/ImageMagick"
      mkdir -pm 755 "${config.xdg.configHome}/nix"
      mkdir -pm 755 "${config.xdg.configHome}/op"
      mkdir -pm 755 "${config.xdg.configHome}/nvim"
      # Node/npm tools (npm doesn't support XDG but we use NPM_CONFIG_USERCONFIG)
      mkdir -pm 755 "${config.xdg.configHome}/npm"
      mkdir -pm 755 "${config.xdg.configHome}/docker"
      mkdir -pm 755 "${config.xdg.configHome}/containers"
      mkdir -pm 755 "${config.xdg.configHome}/dig"
      mkdir -pm 755 "${config.xdg.configHome}/gh"
      mkdir -pm 755 "${config.xdg.configHome}/gitleaks"
      mkdir -pm 755 "${config.xdg.configHome}/lazygit"
      mkdir -pm 755 "${config.xdg.configHome}/lazydocker"
      mkdir -pm 755 "${config.xdg.configHome}/ctop"
      mkdir -pm 755 "${config.xdg.configHome}/dive"
      mkdir -pm 755 "${config.xdg.configHome}/hadolint"
      mkdir -pm 755 "${config.xdg.configHome}/wezterm"
      mkdir -pm 755 "${config.xdg.configHome}/xh"
      mkdir -pm 755 "${config.xdg.configHome}/yt-dlp"
      mkdir -pm 755 "${config.xdg.configHome}/shellcheck"
      mkdir -pm 755 "${config.xdg.configHome}/broot"
      mkdir -pm 755 "${config.xdg.configHome}/mcfly"
      mkdir -pm 755 "${config.xdg.configHome}/eza"
      mkdir -pm 755 "${config.xdg.configHome}/fd"
      mkdir -pm 755 "${config.xdg.configHome}/duti"
      mkdir -pm 755 "${config.xdg.configHome}/ripgrep"
      mkdir -pm 755 "${config.xdg.configHome}/fastfetch"
      # File Analysis & Diff Tools
      mkdir -pm 755 "${config.xdg.configHome}/tokei"
      mkdir -pm 755 "${config.xdg.configHome}/file"
      # System Monitoring Tools
      mkdir -pm 755 "${config.xdg.configHome}/procs"
      mkdir -pm 755 "${config.xdg.configHome}/dust"
      # Media Processing
      mkdir -pm 755 "${config.xdg.configHome}/ffmpeg"
      mkdir -pm 755 "${config.xdg.configHome}/bottom"
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
      mkdir -pm 755 "${config.xdg.configHome}/luacheck"
      # Formatting tools (only those that support XDG)
      mkdir -pm 755 "${config.xdg.configHome}/yamllint"
      # Java
      mkdir -pm 755 "${config.xdg.configHome}/java"
      # Build & Task Automation
      mkdir -pm 755 "${config.xdg.configHome}/just"
      mkdir -pm 755 "${config.xdg.configHome}/pre-commit"
      mkdir -pm 755 "${config.xdg.configHome}/cargo-audit"
      mkdir -pm 755 "${config.xdg.configHome}/cargo-deny"
      mkdir -pm 755 "${config.xdg.configHome}/nox" # Python testing orchestrator
      # SQL Tools
      mkdir -pm 755 "${config.xdg.configHome}/sqlfluff"
      # Backup & Sync
      mkdir -pm 755 "${config.xdg.configHome}/restic"
      mkdir -pm 755 "${config.xdg.configHome}/rclone"
      # Data Processing
      mkdir -pm 755 "${config.xdg.configHome}/fx"
      mkdir -pm 755 "${config.xdg.configHome}/jless"
      # Document Processing
      mkdir -pm 755 "${config.xdg.configHome}/pandoc"
      # Utilities
      mkdir -pm 755 "${config.xdg.configHome}/tldr"
      mkdir -pm 755 "${config.xdg.configHome}/watchexec"
      mkdir -pm 755 "${config.xdg.configHome}/vivid"
      mkdir -pm 755 "${config.xdg.configHome}/yazi"
      mkdir -pm 755 "${config.xdg.configHome}/yazi/plugins"  # Yazi plugins directory
      mkdir -pm 755 "${config.xdg.configHome}/yazi/flavors"  # Yazi flavors/themes directory
      # UI Tools
      mkdir -pm 755 "${config.xdg.configHome}/yabai"
      mkdir -pm 755 "${config.xdg.configHome}/sketchybar"
      mkdir -pm 755 "${config.xdg.configHome}/sketchybar/helpers"
      mkdir -pm 755 "${config.xdg.configHome}/sketchybar/items" 
      mkdir -pm 755 "${config.xdg.configHome}/sketchybar/plugins"
      mkdir -pm 755 "${config.xdg.dataHome}/applications"
      mkdir -pm 755 "${config.xdg.dataHome}/fonts"
      mkdir -pm 755 "${config.xdg.dataHome}/icons"
      mkdir -pm 755 "${config.xdg.dataHome}/backups"
      mkdir -pm 755 "${config.xdg.dataHome}/nix-defexpr"
      # Development tools
      mkdir -pm 755 "${config.xdg.dataHome}/cargo"
      mkdir -pm 755 "${config.xdg.dataHome}/rustup"
      mkdir -pm 755 "${config.xdg.dataHome}/go"
      # Node package managers (npm needs NPM_CONFIG_PREFIX, pnpm is XDG-compliant)
      mkdir -pm 755 "${config.xdg.dataHome}/npm"
      mkdir -pm 755 "${config.xdg.dataHome}/pnpm"
      mkdir -pm 755 "${config.xdg.dataHome}/pnpm/store"
      mkdir -pm 755 "${config.xdg.dataHome}/pnpm/global"
      mkdir -pm 755 "${config.xdg.dataHome}/pipx"
      # NOTE: gradle not installed - removed directory
      mkdir -pm 755 "${config.xdg.dataHome}/docker-machine"
      mkdir -pm 755 "${config.xdg.dataHome}/docker/certs"
      mkdir -pm 755 "${config.xdg.dataHome}/colima"
      mkdir -pm 755 "${config.xdg.dataHome}/podman"
      # NOTE: gnupg not installed - removed directory
      # Build & Task Automation
      mkdir -pm 755 "${config.xdg.dataHome}/pre-commit"
      # Shell tools data
      mkdir -pm 755 "${config.xdg.dataHome}/broot"
      mkdir -pm 755 "${config.xdg.dataHome}/zoxide"
      mkdir -pm 755 "${config.xdg.dataHome}/mcfly"
      # Document processing data
      mkdir -pm 755 "${config.xdg.dataHome}/pandoc"
      mkdir -pm 755 "${config.xdg.dataHome}/pandoc/defaults"
      mkdir -pm 755 "${config.xdg.dataHome}/pandoc/templates"
      mkdir -pm 755 "${config.xdg.dataHome}/pandoc/filters"
      mkdir -pm 755 "${config.xdg.dataHome}/pandoc/csl"
      # Media Processing
      mkdir -pm 755 "${config.xdg.dataHome}/ffmpeg"
      # File Analysis & Diff Tools
      mkdir -pm 755 "${config.xdg.dataHome}/file"
      mkdir -pm 755 "${config.xdg.dataHome}/tokei"
      # Tool-specific data directories
      mkdir -pm 755 "${config.xdg.dataHome}/vivid"
      mkdir -pm 755 "${config.xdg.dataHome}/yazi"
      mkdir -pm 755 "${config.xdg.dataHome}/cargo-audit"
      mkdir -pm 755 "${config.xdg.dataHome}/cargo-generate"
      mkdir -pm 755 "${config.xdg.dataHome}/nox" # Python testing data
      # Trash (FreeDesktop.org specification)
      mkdir -pm 755 "${config.xdg.dataHome}/Trash"
      mkdir -pm 755 "${config.xdg.dataHome}/Trash/files"
      mkdir -pm 755 "${config.xdg.dataHome}/Trash/info"
      # --- State Directories -----------------------------------------------
      mkdir -pm 755 "${config.xdg.stateHome}/nix"
      mkdir -pm 755 "${config.xdg.stateHome}/logs"
      mkdir -pm 755 "${config.xdg.stateHome}/bash"
      mkdir -pm 755 "${config.xdg.stateHome}/zsh"
      mkdir -pm 755 "${config.xdg.cacheHome}/zsh"
      mkdir -pm 755 "${config.xdg.stateHome}/less"
      mkdir -pm 755 "${config.xdg.stateHome}/python"
      mkdir -pm 755 "${config.xdg.stateHome}/pnpm" # pnpm uses XDG_STATE_HOME directly
      mkdir -pm 755 "${config.xdg.stateHome}/sqlite"
      mkdir -pm 755 "${config.xdg.stateHome}/ffmpeg"
      mkdir -pm 755 "${config.xdg.stateHome}/wezterm"  # For daemon socket and logs
      mkdir -pm 755 "${config.xdg.stateHome}/yazi"     # For yazi state and logs
      # --- Cache Directories -----------------------------------------------
      mkdir -pm 755 "${config.xdg.cacheHome}/nix"
      mkdir -pm 755 "${config.xdg.cacheHome}/op"
      mkdir -pm 755 "${config.xdg.cacheHome}/ssh"
      mkdir -pm 755 "${config.xdg.cacheHome}/claude"
      mkdir -pm 755 "${config.xdg.cacheHome}/claude/logs"
      mkdir -pm 755 "${config.xdg.cacheHome}/claude/screenshots"
      mkdir -pm 755 "${config.xdg.cacheHome}/fontconfig"
      # Media processing caches
      mkdir -pm 755 "${config.xdg.cacheHome}/ImageMagick"
      mkdir -pm 755 "${config.xdg.cacheHome}/yt-dlp"
      mkdir -pm 755 "${config.xdg.cacheHome}/ffmpeg"
      # Node package manager caches
      mkdir -pm 755 "${config.xdg.cacheHome}/npm" # npm cache (not XDG-aware but uses this)
      mkdir -pm 755 "${config.xdg.cacheHome}/pnpm" # pnpm uses XDG_CACHE_HOME directly
      mkdir -pm 755 "${config.xdg.cacheHome}/ncu" # npm-check-updates cache
      mkdir -pm 755 "${config.xdg.cacheHome}/pip"
      mkdir -pm 755 "${config.xdg.cacheHome}/pypoetry"
      mkdir -pm 755 "${config.xdg.cacheHome}/pylint"
      mkdir -pm 755 "${config.xdg.cacheHome}/ruff"
      mkdir -pm 755 "${config.xdg.cacheHome}/basedpyright"
      mkdir -pm 755 "${config.xdg.cacheHome}/mypy"
      mkdir -pm 755 "${config.xdg.cacheHome}/uv"
      mkdir -pm 755 "${config.xdg.cacheHome}/pytest"
      mkdir -pm 755 "${config.xdg.cacheHome}/nox" # Python testing orchestrator
      mkdir -pm 755 "${config.xdg.cacheHome}/cargo"
      mkdir -pm 755 "${config.xdg.cacheHome}/sccache"
      mkdir -pm 755 "${config.xdg.cacheHome}/flamegraph" # Performance profiling
      mkdir -pm 755 "${config.xdg.cacheHome}/shellcheck"
      mkdir -pm 755 "${config.xdg.cacheHome}/nix-index"
      # Container runtime caches
      mkdir -pm 755 "${config.xdg.cacheHome}/docker"
      mkdir -pm 755 "${config.xdg.cacheHome}/colima"
      mkdir -pm 755 "${config.xdg.cacheHome}/podman"
      mkdir -pm 755 "${config.xdg.cacheHome}/lazydocker"
      mkdir -pm 755 "${config.xdg.cacheHome}/ctop"
      mkdir -pm 755 "${config.xdg.cacheHome}/dive"
      mkdir -pm 755 "${config.xdg.cacheHome}/buildkit"
      # Shell tools caches
      mkdir -pm 755 "${config.xdg.cacheHome}/bat"
      mkdir -pm 755 "${config.xdg.cacheHome}/direnv"
      mkdir -pm 755 "${config.xdg.cacheHome}/fd"
      # Security tools caches
      mkdir -pm 755 "${config.xdg.cacheHome}/gitleaks"
      # Lua tools caches
      mkdir -pm 755 "${config.xdg.cacheHome}/lua-language-server"
      # Build & Task Automation caches
      mkdir -pm 755 "${config.xdg.cacheHome}/pre-commit"
      # SQL Tools caches
      mkdir -pm 755 "${config.xdg.cacheHome}/sqlfluff"
      # Backup & Sync caches
      mkdir -pm 755 "${config.xdg.cacheHome}/restic"
      mkdir -pm 755 "${config.xdg.cacheHome}/rclone"
      # Utilities caches
      mkdir -pm 755 "${config.xdg.cacheHome}/tldr"
      mkdir -pm 755 "${config.xdg.cacheHome}/vivid"
      mkdir -pm 755 "${config.xdg.cacheHome}/yazi"
      mkdir -pm 755 "${config.xdg.cacheHome}/yazi/plugins"  # Plugin installation cache
      mkdir -pm 755 "${config.xdg.cacheHome}/cargo-audit"
      mkdir -pm 755 "${config.xdg.cacheHome}/cargo-generate"
      mkdir -pm 755 "${config.xdg.cacheHome}/cachix"
      mkdir -pm 755 "${config.xdg.cacheHome}/hadolint"
      # --- Non-XDG Directories ---------------------------------------------
      mkdir -pm 700 "${config.home.homeDirectory}/.ssh"
      mkdir -pm 700 "${config.home.homeDirectory}/.ssh/sockets"
      # w3m (not XDG-compliant, uses ~/.w3m)
      mkdir -pm 755 "${config.home.homeDirectory}/.w3m"
      mkdir -pm 755 "${config.home.homeDirectory}/.local/bin"
      mkdir -pm 755 "${config.home.homeDirectory}/.local/lib"
      mkdir -pm 755 "${config.home.homeDirectory}/.local/lib/sqlean"
      mkdir -pm 755 "${config.home.homeDirectory}/.local/lib/sqlite-vec"
      mkdir -pm 755 "${config.home.homeDirectory}/bin"
      # Cargo-specific directories (not XDG-compliant)
      mkdir -pm 755 "${config.home.homeDirectory}/.cargo"
      mkdir -pm 755 "${config.home.homeDirectory}/.cargo/advisory-db"

      echo "  ✓ XDG directory structure created"
    '';
  };
}
