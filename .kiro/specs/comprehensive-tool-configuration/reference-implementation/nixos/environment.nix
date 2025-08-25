# Title         : environment.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/nixos/environment.nix
# ----------------------------------------------------------------------------
# NixOS-specific environment variables and paths for Linux integration

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  home.sessionVariables = {
    # --- Linux System Integration -----------------------------------------
    # Use Linux-specific browser command
    BROWSER = "xdg-open";
    
    # Linux-specific editor integration
    EDITOR = lib.mkDefault "nvim";
    VISUAL = lib.mkDefault "nvim";
    
    # Linux-specific pager
    PAGER = "less";
    LESS = "-R --use-color -Dd+r$Du+b$";
    
    # --- XDG Base Directory Specification ---------------------------------
    # These are typically set by the system, but ensure they're correct
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
    XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
    XDG_RUNTIME_DIR = "/run/user/$(id -u)";
    
    # Additional XDG directories
    XDG_DATA_DIRS = "/usr/local/share:/usr/share";
    XDG_CONFIG_DIRS = "/etc/xdg";
    
    # --- Desktop Integration ----------------------------------------------
    # Desktop environment (adjust based on actual desktop)
    XDG_CURRENT_DESKTOP = lib.mkDefault "GNOME";
    XDG_SESSION_TYPE = lib.mkDefault "wayland";
    XDG_SESSION_DESKTOP = lib.mkDefault "gnome";
    DESKTOP_SESSION = lib.mkDefault "gnome";
    
    # Application launcher integration
    XDG_MENU_PREFIX = "gnome-";
    
    # --- SSH and GPG Integration ------------------------------------------
    # SSH agent integration
    SSH_AUTH_SOCK = "${config.xdg.runtimeDir}/ssh-agent.socket";
    
    # GPG agent integration
    GNUPGHOME = "${config.xdg.dataHome}/gnupg";
    GPG_TTY = "$(tty)";
    
    # --- Container Runtime (Linux-Specific) -------------------------------
    # Docker Linux-specific
    DOCKER_HOST = "unix:///var/run/docker.sock";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";
    
    # Podman Linux-specific
    CONTAINERS_CONF = "${config.xdg.configHome}/containers/containers.conf";
    CONTAINERS_REGISTRIES_CONF = "${config.xdg.configHome}/containers/registries.conf";
    CONTAINERS_STORAGE_CONF = "${config.xdg.configHome}/containers/storage.conf";
    PODMAN_USERNS = "keep-id";
    
    # --- Font Configuration (Linux-Specific) -----------------------------
    FONTCONFIG_PATH = "${config.xdg.configHome}/fontconfig";
    FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    FONTCONFIG_CACHE = "${config.xdg.cacheHome}/fontconfig";
    FC_DEBUG = "0";
    FC_LANG = "en";
    
    # --- systemd Integration ----------------------------------------------
    SYSTEMD_USER_CONFIG_DIR = "${config.xdg.configHome}/systemd/user";
    SYSTEMD_USER_DATA_DIR = "${config.xdg.dataHome}/systemd/user";
    SYSTEMD_LOG_LEVEL = "info";
    SYSTEMD_LOG_TARGET = "journal";
    
    # --- Development Tools (Linux-Specific Features) ---------------------
    # Neovim Linux-specific
    NVIM_APPNAME = "nvim";
    NVIM_LOG_FILE = "${config.xdg.stateHome}/nvim/log";
    
    # Git Linux-specific
    GIT_SSH_COMMAND = "ssh -o ControlMaster=auto -o ControlPersist=60s";
    
    # --- Shell Integration (Linux-Specific) ------------------------------
    # Shell path (NixOS-specific)
    SHELL = "/run/current-system/sw/bin/zsh";
    
    # Terminal configuration
    TERM = lib.mkDefault "xterm-256color";
    COLORTERM = "truecolor";
    FORCE_COLOR = "1";
    
    # History files (XDG-compliant)
    HISTFILE = "${config.xdg.dataHome}/zsh/history";
    
    # --- Language-Specific Environment Variables -------------------------
    # Python
    PYTHONUSERBASE = "${config.xdg.dataHome}/python";
    PYTHONHISTORY = "${config.xdg.stateHome}/python/history";
    PYTHON_EGG_CACHE = "${config.xdg.cacheHome}/python-eggs";
    
    # Node.js
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/history";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    NPM_CONFIG_TMP = "${config.xdg.runtimeDir}/npm";
    
    # Rust
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    
    # Go
    GOPATH = "${config.xdg.dataHome}/go";
    GOCACHE = "${config.xdg.cacheHome}/go-build";
    GOMODCACHE = "${config.xdg.cacheHome}/go/mod";
    
    # --- Security and Privacy (Linux-Specific) ---------------------------
    # Disable telemetry for various tools
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    
    # --- Performance Optimizations ---------------------------------------
    # Parallel make jobs (adjust based on CPU cores)
    MAKEFLAGS = "-j$(nproc)";
    
    # Ninja build parallelism
    NINJA_STATUS = "[%f/%t] ";
    
    # --- Locale Configuration --------------------------------------------
    # Ensure proper locale settings
    LC_ALL = lib.mkDefault "en_US.UTF-8";
    LANG = lib.mkDefault "en_US.UTF-8";
    LC_CTYPE = lib.mkDefault "en_US.UTF-8";
    
    # --- Network Configuration -------------------------------------------
    # Curl configuration
    CURL_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
    
    # Wget configuration
    WGETRC = "${config.xdg.configHome}/wget/wgetrc";
    
    # --- Debugging and Development ---------------------------------------
    # Enable debug symbols for core dumps
    DEBUGINFOD_URLS = "https://debuginfod.nixos.org";
    
    # GDB configuration
    GDBHISTFILE = "${config.xdg.stateHome}/gdb/history";
    
    # Valgrind configuration
    VALGRIND_OPTS = "--log-file=${config.xdg.stateHome}/valgrind/valgrind.log";
    
    # --- Application-Specific Configuration ------------------------------
    # Less configuration
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    LESSKEY = "${config.xdg.configHome}/less/lesskey";
    
    # Readline configuration
    INPUTRC = "${config.xdg.configHome}/readline/inputrc";
    
    # Vim configuration (fallback)
    VIMINIT = "source ${config.xdg.configHome}/vim/vimrc";
    
    # --- Container Development Environment -------------------------------
    # Development container settings
    DEVCONTAINER_CONFIG = "${config.xdg.configHome}/devcontainer";
    
    # Docker Compose settings
    COMPOSE_FILE = "docker-compose.yml:docker-compose.override.yml";
    COMPOSE_PROJECT_NAME = "$(basename $(pwd))";
    
    # --- Build System Integration ----------------------------------------
    # CMake configuration
    CMAKE_GENERATOR = "Ninja";
    CMAKE_EXPORT_COMPILE_COMMANDS = "1";
    
    # Meson configuration
    MESON_BUILD_ROOT = "${config.xdg.cacheHome}/meson";
    
    # --- Version Control Integration -------------------------------------
    # Git configuration
    GIT_CONFIG_GLOBAL = "${config.xdg.configHome}/git/config";
    GIT_CONFIG_SYSTEM = "/etc/gitconfig";
    
    # Mercurial configuration
    HGRCPATH = "${config.xdg.configHome}/hg/hgrc";
    
    # --- Monitoring and Logging ------------------------------------------
    # Journal configuration
    SYSTEMD_LESS = "FRXMK";
    
    # Log file locations
    LOGDIR = "${config.xdg.stateHome}/logs";
  };

  # --- Linux-Specific PATH Extensions -----------------------------------
  home.sessionPath = [
    # User-specific binary paths
    "${config.home.homeDirectory}/.local/bin"
    
    # NixOS system paths
    "/run/current-system/sw/bin"
    "/run/current-system/sw/sbin"
    
    # Standard Linux paths
    "/usr/local/bin"
    "/usr/local/sbin"
    "/usr/bin"
    "/usr/sbin"
    "/bin"
    "/sbin"
    
    # Language-specific paths
    "${config.xdg.dataHome}/cargo/bin"
    "${config.xdg.dataHome}/go/bin"
    "${config.home.homeDirectory}/.local/share/npm/bin"
  ];

  # --- Linux-Specific Shell Integration ---------------------------------
  programs.zsh.initExtra = lib.mkIf config.programs.zsh.enable (lib.mkAfter ''
    # Linux-specific zsh configuration
    
    # Set up XDG runtime directory
    if [[ -z "$XDG_RUNTIME_DIR" ]]; then
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi
    
    # Ensure XDG directories exist
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
    
    # Linux-specific key bindings
    bindkey "^[[1;5C" forward-word      # Ctrl+Right
    bindkey "^[[1;5D" backward-word     # Ctrl+Left
    bindkey "^[[1;3C" forward-word      # Alt+Right
    bindkey "^[[1;3D" backward-word     # Alt+Left
    bindkey "^[[3~" delete-char         # Delete key
    bindkey "^[[H" beginning-of-line    # Home key
    bindkey "^[[F" end-of-line          # End key
    
    # Linux-specific completions
    if [[ -d /run/current-system/sw/share/zsh/site-functions ]]; then
      fpath=(/run/current-system/sw/share/zsh/site-functions $fpath)
    fi
    
    # systemd integration
    if command -v systemctl >/dev/null 2>&1; then
      # Function to check systemd user service status
      systemd-status() {
        if [[ $# -eq 0 ]]; then
          systemctl --user status
        else
          systemctl --user status "$@"
        fi
      }
      
      # Function to follow systemd user service logs
      systemd-logs() {
        if [[ $# -eq 0 ]]; then
          journalctl --user -f
        else
          journalctl --user -f -u "$@"
        fi
      }
    fi
    
    # Container integration
    if command -v podman >/dev/null 2>&1; then
      # Function to clean up containers and images
      podman-cleanup() {
        echo "Cleaning up containers..."
        podman container prune -f
        echo "Cleaning up images..."
        podman image prune -f
        echo "Cleaning up volumes..."
        podman volume prune -f
        echo "Cleanup complete!"
      }
    fi
    
    # Desktop integration
    if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
      # Function to update desktop database
      update-desktop() {
        update-desktop-database "$XDG_DATA_HOME/applications"
        update-mime-database "$XDG_DATA_HOME/mime"
        if command -v gtk-update-icon-cache >/dev/null 2>&1; then
          gtk-update-icon-cache -t "$XDG_DATA_HOME/icons/hicolor" 2>/dev/null || true
        fi
        echo "Desktop database updated"
      }
    fi
    
    # Font management
    if command -v fc-cache >/dev/null 2>&1; then
      # Function to update font cache
      update-fonts() {
        fc-cache -fv
        echo "Font cache updated"
      }
    fi
  '');

  programs.bash.initExtra = lib.mkIf config.programs.bash.enable ''
    # Linux-specific bash configuration
    
    # Set up XDG runtime directory
    if [[ -z "$XDG_RUNTIME_DIR" ]]; then
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi
    
    # Ensure XDG directories exist
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
    
    # Linux-specific completions
    if [[ -d /run/current-system/sw/share/bash-completion/completions ]]; then
      for completion in /run/current-system/sw/share/bash-completion/completions/*; do
        [[ -r "$completion" ]] && source "$completion"
      done
    fi
    
    # systemd integration functions
    if command -v systemctl >/dev/null 2>&1; then
      systemd-status() {
        if [[ $# -eq 0 ]]; then
          systemctl --user status
        else
          systemctl --user status "$@"
        fi
      }
      
      systemd-logs() {
        if [[ $# -eq 0 ]]; then
          journalctl --user -f
        else
          journalctl --user -f -u "$@"
        fi
      }
    fi
  '';
}