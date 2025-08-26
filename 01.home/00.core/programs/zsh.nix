# Title         : 01.home/00.core/programs/zsh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/zsh.nix
# ----------------------------------------------------------------------------
# Zsh shell configuration with modern tooling integration

{
  config,
  pkgs,
  lib,
  myLib,
  context,
  ...
}:

{
  programs.zsh = {
    # --- Core Settings ------------------------------------------------------
    enable = true;
    enableCompletion = true; # Includes zsh-completions
    autosuggestion.enable = true; # zsh-autosuggestions
    syntaxHighlighting.enable = true; # zsh-syntax-highlighting
    historySubstringSearch = {
      enable = true; # zsh-history-substring-search
      searchUpKey = "^[[A"; # Up arrow
      searchDownKey = "^[[B"; # Down arrow
    };
    # --- Shell Aliases ------------------------------------------------------
    shellAliases = lib.mkMerge [
      (import ../aliases/core.nix { })
      (import ../aliases/sysadmin.nix { })
    ];
    # --- Zsh Plugins --------------------------------------------------------
    # Note: All plugins now managed via built-in enable flags above
    plugins = [];
    # --- History Configuration ----------------------------------------------
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 50000;
      save = 50000;
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };
    # --- Init Content -------------------------------------------------------
    initContent = lib.mkMerge [
      # --- Pre-compinit (order 500) -----------------------------------------
      (lib.mkOrder 500 ''
        # Note: All zsh plugins (autosuggestions, syntax-highlighting, history-substring-search, completions)
        # are now loaded via home-manager's built-in integration options

        # Additional keybindings for history substring search
        bindkey '^P' history-substring-search-up       # Ctrl+P
        bindkey '^N' history-substring-search-down     # Ctrl+N
      '')
      # --- Order 550 --------------------------------------------------------
      (lib.mkOrder 550 ''
        # Placeholder for modern command replacements
        # This section reserved for future Unix command modernization
        # e.g., ls -> eza, cat -> bat, find -> fd, grep -> rg
      '')
      # --- Order 600 --------------------------------------------------------
      (lib.mkOrder 600 ''
        # Smart package info lookup
        nix-info() {
          [[ $# -lt 1 ]] && {
            echo "Store size: $(du -sh /nix/store 2>/dev/null | cut -f1)"
            echo "Generations: $(nix-env --list-generations 2>/dev/null | wc -l)"
          } || {
            nix path-info --closure-size -h "nixpkgs#$1" 2>/dev/null || \
            nix-store --query --roots "$1" 2>/dev/null || \
            echo "Not found: $1"
          }
        }

        # Quick dev shell with common tools
        dev-shell() {
          echo "Starting dev shell with common tools..."
          nix-shell -p git nodejs python3 xh jq ripgrep fd bat
        }

        # What's using disk space?
        nix-biggest() {
          echo "Analyzing store (this may take a moment)..."
          nix-du | head -20
        }

        # Trace nix builds with detailed output
        ntrace() {
          nix build --print-build-logs --show-trace "$@" 2>&1 | tee build.log
        }
      '')
      # --- Post-compinit (order 650) - Main Configuration -------------------
      (lib.mkOrder 650 ''
        # Nix-index database management
        nix-index-auto() {
          local check_marker="$NIX_INDEX_DATABASE/.last-check"
          local db_marker="$NIX_INDEX_DATABASE/.last-update"

          # Only check once per day
          [[ -f "$check_marker" ]] && [[ $(find "$check_marker" -mmin -1440 2>/dev/null) ]] && return

          mkdir -p "$NIX_INDEX_DATABASE" && touch "$check_marker"

          if [[ ! -f "$NIX_INDEX_DATABASE/files" ]]; then
            echo "Building nix-index database..."
            (nix-index 2>/dev/null && touch "$db_marker") &!
          elif [[ -f "$db_marker" ]] && [[ $(find "$db_marker" -mtime +7 2>/dev/null) ]]; then
            echo "Updating nix-index database..."
            (nix-index 2>/dev/null && touch "$db_marker") &!
          fi
        }

        nix-index-auto

        # 1Password CLI plugin aliases
        [ -f "$HOME/.config/op/plugins.sh" ] && source "$HOME/.config/op/plugins.sh"

        # Darwin rebuild helper
        ${lib.optionalString pkgs.stdenv.isDarwin ''
          darwin() {
            darwin-rebuild "$@" --flake "$PWD"
          }
        ''}

        # Docker/Colima/Podman socket detection helper
        _set_docker_host() {
          [ -S "$HOME/.colima/default/docker.sock" ] && export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock" && return
          [ -S "$HOME/.colima/docker.sock" ] && export DOCKER_HOST="unix://$HOME/.colima/docker.sock" && return
          [ -S "$HOME/.docker/run/docker.sock" ] && export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock" && return
          command -v podman &>/dev/null && podman machine list 2>/dev/null | grep -q Running && \
            export DOCKER_HOST="unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null || echo "")"
        }

        # Docker/Colima/Podman helpers with dynamic socket detection
        docker-start() {
          command -v colima &>/dev/null && {
            pgrep -q colima || { echo "Starting Colima..." && colima start; }
            _set_docker_host
          } || command -v podman &>/dev/null && {
            podman machine list --format "{{.Running}}" | grep -q true || {
              echo "Starting Podman..." && podman machine start
            }
            _set_docker_host
          } || echo "No container runtime found (colima/podman)"

          [ -n "$DOCKER_HOST" ] && echo "Container runtime ready at $DOCKER_HOST"
        }

        # Set DOCKER_HOST if socket exists
        _set_docker_host

        # Set SSH_AUTH_SOCK for 1Password if available
        # Socket path is platform-aware via myLib.secrets.opSSHSocket
        ONEPASS_SOCKET="${myLib.secrets.opSSHSocket context}"
        [ -S "$ONEPASS_SOCKET" ] && export SSH_AUTH_SOCK="$ONEPASS_SOCKET"
        unset ONEPASS_SOCKET

        # Quick Python environment setup
        pysetup() {
          [ -f "pyproject.toml" ] && { echo "pyproject.toml already exists"; return 1; }
          poetry init -n
          poetry add --group dev ruff pytest
          echo "Python project initialized with Poetry"
          echo "Virtual environment will be created in .venv/"
        }

        # Rust compilation cache status (sccache)
        ruscache() {
          command -v sccache &>/dev/null && {
            echo "🦀 Rust compilation cache status:"
            sccache --show-stats
          } || echo "sccache not available"
        }

        # Project detection and LSP auto-initialization
        project-detect() {
          [[ -f "flake.nix" ]] && echo "❄️  Project: Nix Flake (nil LSP available)" && return
          [[ -f "package.json" ]] && {
            [[ -f "tsconfig.json" ]] && echo "📦 Project: TypeScript (typescript-language-server available)" || \
              echo "📦 Project: Node.js (typescript-language-server available)"
            return
          }
          [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]] && \
            echo "🐍 Project: Python (basedpyright available)" && return
          [[ -f "Cargo.toml" ]] && echo "🦀 Project: Rust (rust-analyzer available)" && return
          [[ -f "go.mod" ]] && echo "🐹 Project: Go (gopls needs installation)" && return
          [[ -n "$(find . -maxdepth 1 -name "*.lua" 2>/dev/null)" ]] || [[ -f ".luarc.json" ]] && \
            echo "🌙 Project: Lua (lua-language-server available)" && return
          [[ -f "Dockerfile" ]] || [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]] && \
            echo "🐳 Project: Docker (hadolint available for Dockerfiles)"
        }

        # Auto-detect on directory change
        autoload -U add-zsh-hook
        add-zsh-hook chpwd project-detect


        # Zoxide integration
        command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

        # ZSH syntax highlighting styles (for paths)
        typeset -A ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES[path]=none
        ZSH_HIGHLIGHT_STYLES[path_prefix]=none

        # WezTerm Shell Integration
        [[ -n "$WEZTERM_PANE" ]] && {
          function _wezterm_set_user_var() {
            printf "\\033]1337;SetUserVar=%s=%s\\007" "$1" "$(echo -n "$2" | base64)"
          }

          function _wezterm_check_git() {
            git rev-parse --git-dir >/dev/null 2>&1 && \
              _wezterm_set_user_var "IS_GIT_REPO" "true" || \
              _wezterm_set_user_var "IS_GIT_REPO" "false"
          }

          add-zsh-hook chpwd _wezterm_check_git
          add-zsh-hook precmd _wezterm_check_git
          _wezterm_check_git
        }

        # Python venv auto-activation
        auto-venv() {
          [[ -f ".venv/bin/activate" ]] && source .venv/bin/activate || {
            [[ -n "$VIRTUAL_ENV" ]] && [[ ! -f ".venv/bin/activate" ]] && deactivate 2>/dev/null || true
          }
        }
        add-zsh-hook chpwd auto-venv
      '')
      # --- Last-stage integrations (order 1000) -----------------------------
      (lib.mkOrder 1000 ''
        # Kiro terminal integration (when using Kiro terminal)
        [[ "$TERM_PROGRAM" == "kiro" ]] && [ -f "$(kiro --locate-shell-integration-path zsh 2>/dev/null)" ] && \
          . "$(kiro --locate-shell-integration-path zsh)"
      '')
      # --- Very last items (order 5000) -------------------------------------
      (lib.mkOrder 5000 ''
        # Source local customizations (mutable file for manual additions)
        # This allows tools installed outside Nix to add their configs
        # and provides a place for temporary tweaks without rebuilding
        [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
      '')
    ];
  };
  # --- Shell Integration Files ----------------------------------------------
  home.file = {
    ".zshrc.local" = {
      text = ''
        # Local zsh customizations
        # This file is not managed by Nix - add your temporary tweaks here
      '';
      onChange = "touch $HOME/.zshrc.local";
    };
  };
}
