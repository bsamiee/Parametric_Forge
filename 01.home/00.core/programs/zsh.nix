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
    plugins = [ ];
    # --- History Configuration ----------------------------------------------
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000; # Increased from 50000 for better history retention
      save = 100000;
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      ignoreAllDups = true; # Remove older duplicates
      expireDuplicatesFirst = true;
    };
    # --- Init Content -------------------------------------------------------
    initContent = lib.mkMerge [
      # --- Performance & Module Loading (order 100) --------------------------
      # These load zsh modules early for better performance and capabilities
      (lib.mkOrder 100 ''
        # MODULES: Load zsh internal modules for advanced features
        zmodload zsh/zpty      # Pseudo-terminal operations (for async)
        zmodload zsh/system    # System interaction capabilities
        zmodload zsh/parameter # Advanced parameter manipulation
        
        # PERFORMANCE: Skip security check on trusted directories
        zstyle ':completion:*' accept-exact-dirs true
        
        # HISTORY OPTIONS: Advanced history behavior settings
        setopt HIST_VERIFY         # Show command before executing from history
        setopt HIST_REDUCE_BLANKS  # Clean up extra spaces in history
        setopt HIST_NO_FUNCTIONS   # Don't save function definitions
        setopt SHARE_HISTORY       # Share history between all sessions
        setopt INC_APPEND_HISTORY  # Write to history immediately
        
        # DIRECTORY NAVIGATION: Enhanced cd and directory behavior
        setopt AUTO_PUSHD          # Automatically maintain directory stack
        setopt PUSHD_IGNORE_DUPS   # Don't duplicate directories in stack
        setopt PUSHD_SILENT        # Don't print directory stack after pushd
        setopt CDABLE_VARS         # Allow cd to variable values
        
        # JOB CONTROL: Better background job management
        setopt CHECK_JOBS          # Warn about running jobs when exiting
        setopt HUP                 # Send HUP signal to jobs when shell exits
        setopt LONG_LIST_JOBS      # Display PID when suspending processes
      '')
      
      # --- Completion System (order 200) ------------------------------------
      (lib.mkOrder 200 ''
        # Advanced completion with fzf integration
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
        zstyle ':completion:*:warnings' format '%F{red}No matches found%f'
        zstyle ':completion:*' accept-exact '*(N)'
        zstyle ':completion:*' use-cache true
        zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/completion-cache"
        zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
        zstyle ':completion:*' special-dirs true
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback localhost broadcasthost
        
        # FZF-TAB integration (if available)
        command -v fzf >/dev/null 2>&1 && {
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null'
          zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
          zstyle ':fzf-tab:*' switch-group '<' '>'
        }
      '')
      
      # --- Utility Functions & Helpers (order 300) ---------------------------
      # Helper functions for performance and security
      (lib.mkOrder 300 ''
        # Enhanced command not found handler
        command_not_found_handler() {
          case "$1" in
            rm|mv|dd|format|fdisk|sudo) echo "Command '$1' not found (dangerous command)"; return 127 ;;
            *) command -v nix-locate >/dev/null 2>&1 && 
               { echo "Searching nixpkgs for '$1'..."; nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$1"; } || 
               echo "Command '$1' not found"; return 127 ;;
          esac
        }
        
        # Project root navigation
        project-root() {
          cd "$(git rev-parse --show-toplevel 2>/dev/null || 
               fd -t d '^(.git|.hg|.svn|flake.nix|Cargo.toml|package.json|pyproject.toml)$' --max-depth 3 --exec dirname {} | head -1)" 2>/dev/null || 
          echo "Not in a project"
        }
      '')
      
      # --- Pre-compinit (order 500) -----------------------------------------
      (lib.mkOrder 500 ''
        # Note: All zsh plugins (autosuggestions, syntax-highlighting, history-substring-search, completions)
        # are now loaded via home-manager's built-in integration options

        # KEYBINDINGS: Additional keyboard shortcuts
        # Enhanced navigation (preserving mcfly's ^R)
        bindkey '^P' history-substring-search-up       # Ctrl+P - search history up
        bindkey '^N' history-substring-search-down     # Ctrl+N - search history down
        # Note: ^R reserved for mcfly integration
        
        # Word navigation (useful in terminals)
        bindkey '^[[1;5C' forward-word   # Ctrl+Right - jump word forward
        bindkey '^[[1;5D' backward-word  # Ctrl+Left - jump word backward
        bindkey '^[[H' beginning-of-line # Home - go to line start
        bindkey '^[[F' end-of-line      # End - go to line end
        
        # Edit command in editor
        autoload -z edit-command-line
        zle -N edit-command-line
        bindkey '^X^E' edit-command-line # Ctrl+X Ctrl+E - edit in $EDITOR
      '')
      # --- Environment Optimization (order 550) ----------------------------
      (lib.mkOrder 550 ''
        # Startup optimizations
        typeset -U path PATH
        mkdir -p "${config.xdg.cacheHome}/zsh" "${config.xdg.stateHome}/zsh"
        
        # Context-aware optimizations
        [[ -n "$NVIM$VSCODE_PID" ]] && { zstyle ':completion:*' max-matches-width 0; zstyle ':completion:*' max-matches 10; }
        [[ -n "$SSH_CLIENT$SSH_TTY" ]] && { HISTSIZE=10000; SAVEHIST=10000; }
      '')
      # --- Nix Utilities (order 600) ---------------------------------------
      (lib.mkOrder 600 ''
        # Package info and dev shell launcher
        nix-info() {
          [[ $# -lt 1 ]] && { echo "Store: $(du -sh /nix/store 2>/dev/null | cut -f1), Generations: $(nix-env --list-generations 2>/dev/null | wc -l)"; } ||
          nix path-info --closure-size -h "nixpkgs#$1" 2>/dev/null || nix-store --query --roots "$1" 2>/dev/null || echo "Not found: $1"
        }
        
        dev-shell() {
          local packages=(git jq ripgrep fd bat)
          [[ -f "package.json" ]] && packages+=(nodejs)
          [[ -f "pyproject.toml" ]] && packages+=(python3) 
          [[ -f "Cargo.toml" ]] && packages+=(rustc cargo)
          [[ -f "go.mod" ]] && packages+=(go)
          echo "Dev shell: ''${packages[*]}"; nix-shell -p ''${packages[*]}
        }
        
        nix-biggest() { echo "Analyzing store..."; nix-du | head -20; }
        ntrace() { nix build --print-build-logs --show-trace "$@" 2>&1 | tee build.log; }
      '')
      # --- Post-compinit (order 650) - Main Configuration -------------------
      (lib.mkOrder 650 ''
        # Nix-index database management
        nix-index-auto() {
          local check_marker="$NIX_INDEX_DATABASE/.last-check"
          [[ -f "$check_marker" ]] && [[ $(find "$check_marker" -mmin -1440 2>/dev/null) ]] && return
          mkdir -p "$NIX_INDEX_DATABASE" && touch "$check_marker"
          [[ ! -f "$NIX_INDEX_DATABASE/files" ]] && { echo "Building nix-index..."; (nix-index 2>/dev/null) &! }
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

        # Container runtime management
        _set_docker_host() {
          [ -S "$HOME/.colima/docker.sock" ] && export DOCKER_HOST="unix://$HOME/.colima/docker.sock" && return
          [ -S "$HOME/.docker/run/docker.sock" ] && export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock" && return
          command -v podman &>/dev/null && podman machine list 2>/dev/null | grep -q Running &&
            export DOCKER_HOST="unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)"
        }
        
        docker-start() {
          command -v colima &>/dev/null && { pgrep -q colima || { echo "Starting Colima..."; colima start; }; _set_docker_host; } ||
          command -v podman &>/dev/null && { podman machine list --format "{{.Running}}" | grep -q true || { echo "Starting Podman..."; podman machine start; }; _set_docker_host; } ||
          echo "No container runtime found"
          [ -n "$DOCKER_HOST" ] && echo "Ready at $DOCKER_HOST"
        }
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

        # Rust compilation cache status
        ruscache() {
          command -v sccache &>/dev/null && { echo "Rust cache:"; sccache --show-stats; } || echo "sccache not available"
        }

        # Project detection
        project-info() {
          [[ -f "flake.nix" ]] && echo "Nix" && return
          [[ -f "package.json" ]] && echo "Node" && return  
          [[ -f "Cargo.toml" ]] && echo "Rust" && return
          [[ -f "pyproject.toml" ]] && echo "Python" && return
        }

        # Shell customizations and integrations
        autoload -U add-zsh-hook
        typeset -A ZSH_HIGHLIGHT_STYLES; ZSH_HIGHLIGHT_STYLES[path]=none ZSH_HIGHLIGHT_STYLES[path_prefix]=none
        
        # Auto-activation functions  
        auto-venv() { [[ -f ".venv/bin/activate" ]] && source .venv/bin/activate || { [[ -n "$VIRTUAL_ENV" ]] && [[ ! -f ".venv/bin/activate" ]] && deactivate 2>/dev/null || true; }; }
        
        # Register hooks
        add-zsh-hook chpwd project-info auto-venv
        
        # WezTerm integration
        [[ -n "$WEZTERM_PANE" ]] && {
          _wezterm_set_user_var() { printf "\\033]1337;SetUserVar=%s=%s\\007" "$1" "$(echo -n "$2" | base64)"; }
          _wezterm_check_git() { git rev-parse --git-dir >/dev/null 2>&1 && _wezterm_set_user_var "IS_GIT_REPO" "true" || _wezterm_set_user_var "IS_GIT_REPO" "false"; }
          add-zsh-hook chpwd precmd _wezterm_check_git
          _wezterm_check_git
        }
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
