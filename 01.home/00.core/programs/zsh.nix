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
    syntaxHighlighting.enable = true;
    historySubstringSearch = {
      enable = true; # zsh-history-substring-search
      searchUpKey = "^[[A"; # Up arrow
      searchDownKey = "^[[B"; # Down arrow
    };
    # --- Shell Aliases ------------------------------------------------------
    shellAliases = { };
    # --- Zsh Plugins --------------------------------------------------------
    # Note: All plugins now managed via built-in enable flags above
    plugins = [ ];
    # --- History Configuration ----------------------------------------------
    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
      share = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      expireDuplicatesFirst = true;
    };
    # --- Init Content -------------------------------------------------------
    initContent = lib.mkMerge [
      # --- Performance & Module Loading (order 100) --------------------------
      (lib.mkOrder 100 ''
        zmodload zsh/zpty zsh/system zsh/parameter
        zstyle ':completion:*' accept-exact-dirs true

        setopt HIST_VERIFY HIST_REDUCE_BLANKS HIST_NO_FUNCTIONS
        setopt SHARE_HISTORY INC_APPEND_HISTORY
        setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT CDABLE_VARS
        setopt CHECK_JOBS HUP LONG_LIST_JOBS

      '')

      # --- Completion System (order 200) ------------------------------------
      (lib.mkOrder 200 ''
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' list-colors
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
        # Project root navigation
        project-root() {
          cd "$(git rev-parse --show-toplevel 2>/dev/null ||
               fd -t d '^(.git|.hg|.svn|flake.nix|Cargo.toml|package.json|pyproject.toml)$' --max-depth 3 --exec dirname {} | head -1)" 2>/dev/null || 
          echo "Not in a project"
        }

        # Official Yazi shell wrapper with cd-on-quit
        y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }

        # WezTerm CLI helper - routes through wezterm-utils.sh script when available
        weztermctl() {
          local bin
          if [ -n "$WEZTERM_UTILS_BIN" ]; then
            bin="$WEZTERM_UTILS_BIN"
          else
            bin=wezterm-utils.sh
          fi

          if command -v "$bin" >/dev/null 2>&1; then
            command "$bin" "$@"
          elif command -v wezterm-utils.sh >/dev/null 2>&1; then
            command wezterm-utils.sh "$@"
          else
            printf 'weztermctl: wezterm-utils.sh not found in PATH\n' >&2
            return 1
          fi
        }
      '')

      # --- Pre-compinit (order 500) -----------------------------------------
      (lib.mkOrder 500 ''
        bindkey '^P' history-substring-search-up
        bindkey '^N' history-substring-search-down
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line

        autoload -z edit-command-line
        zle -N edit-command-line
        bindkey '^X^E' edit-command-line
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
      # --- Post-compinit (order 650) - Main Configuration -------------------
      (lib.mkOrder 650 ''
        # Auto nix-index management - check if available first
        command -v nindexauto >/dev/null 2>&1 && nindexauto || true

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
        ONEPASS_SOCKET="${myLib.secrets.opSSHSocket context}"
        [ -S "$ONEPASS_SOCKET" ] && export SSH_AUTH_SOCK="$ONEPASS_SOCKET"
        unset ONEPASS_SOCKET
        pysetup() {
          [ -f "pyproject.toml" ] && { echo "pyproject.toml already exists"; return 1; }
          poetry init -n
          poetry add --group dev ruff pytest
          echo "Python project initialized with Poetry"
          echo "Virtual environment will be created in .venv/"
        }

        ruscache() {
          command -v sccache &>/dev/null && { echo "Rust cache:"; sccache --show-stats; } || echo "sccache not available"
        }

        project-info() {
          [[ -f "flake.nix" ]] && echo "Nix" && return
          [[ -f "package.json" ]] && echo "Node" && return
          [[ -f "Cargo.toml" ]] && echo "Rust" && return
          [[ -f "pyproject.toml" ]] && echo "Python" && return
        }

        autoload -U add-zsh-hook

        auto-venv() { [[ -f ".venv/bin/activate" ]] && source .venv/bin/activate || { [[ -n "$VIRTUAL_ENV" ]] && [[ ! -f ".venv/bin/activate" ]] && deactivate 2>/dev/null || true; }; }
        add-zsh-hook chpwd project-info
        add-zsh-hook chpwd auto-venv

      '')
      # --- WezTerm Environment Detection (order 950) ------------------------
      (lib.mkOrder 950 ''
        # Minimal WezTerm integration - only set user vars from existing env
        if [[ "$TERM_PROGRAM" == "WezTerm" ]] && [[ -z "$WEZTERM_SHELL_SKIP_ENV" ]]; then
          # Cache previous values to avoid redundant updates
          typeset -g __wezterm_prev_nix=""
          typeset -g __wezterm_prev_venv=""
          typeset -g __wezterm_prev_node=""

          __wezterm_update_env() {
            # Only set if changed to minimize escape sequences
            local current_nix="''${IN_NIX_SHELL:-0}"
            local current_venv="''${VIRTUAL_ENV##*/}"  # Just basename
            local current_node="''${FNM_USING_VERSION:-}"  # fnm sets this

            if [[ "$current_nix" != "$__wezterm_prev_nix" ]]; then
              printf "\033]1337;SetUserVar=%s=%s\007" "WEZTERM_IN_NIX" "$(echo -n "$current_nix" | base64)"
              __wezterm_prev_nix="$current_nix"
            fi

            if [[ "$current_venv" != "$__wezterm_prev_venv" ]]; then
              printf "\033]1337;SetUserVar=%s=%s\007" "WEZTERM_VENV" "$(echo -n "$current_venv" | base64)"
              __wezterm_prev_venv="$current_venv"
            fi

            if [[ "$current_node" != "$__wezterm_prev_node" ]]; then
              printf "\033]1337;SetUserVar=%s=%s\007" "WEZTERM_NODE" "$(echo -n "$current_node" | base64)"
              __wezterm_prev_node="$current_node"
            fi
          }

          # Only update on directory change and initial prompt
          add-zsh-hook chpwd __wezterm_update_env
          __wezterm_update_env  # Initial call
        fi
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
    };
  };
}
