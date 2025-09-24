# Title         : 01.home/00.core/programs/zsh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/zsh.nix
# ----------------------------------------------------------------------------
# Zsh shell configuration - foundation only

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
    # --- Core Configuration --------------------------------------------------
    enable = true;
    enableCompletion = true;
    completionInit = "autoload -Uz compinit && compinit -C -d \"\$ZSH_COMPDUMP\"";

    # --- Plugin Management ---------------------------------------------------
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch = {
      enable = true;
      searchUpKey = "^[[A"; # Up arrow
      searchDownKey = "^[[B"; # Down arrow
    };

    # --- History Management --------------------------------------------------
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

    # --- Shell Aliases -------------------------------------------------------
    shellAliases = import ../aliases/default.nix { inherit lib; };

    # --- Shell Initialization ------------------------------------------------
    initContent = lib.mkMerge [
      # --- Zsh Options & Modules (order 100) --------------------------------
      (lib.mkOrder 100 ''
        # Load Zsh modules
        zmodload zsh/zpty zsh/system zsh/parameter
        # Directory navigation
        setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT CDABLE_VARS

        # History options
        setopt HIST_VERIFY HIST_REDUCE_BLANKS HIST_NO_FUNCTIONS
        setopt SHARE_HISTORY INC_APPEND_HISTORY

        # Job control
        setopt CHECK_JOBS HUP LONG_LIST_JOBS

        # Completion
        zstyle ':completion:*' accept-exact-dirs true
      '')

      # --- Completion Configuration (order 200) -----------------------------
      (lib.mkOrder 200 ''
        # Completion matching
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

        # Appearance
        zstyle ':completion:*' list-colors
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
        zstyle ':completion:*:warnings' format '%F{red}No matches found%f'

        # Performance
        zstyle ':completion:*' accept-exact '*(N)'
        zstyle ':completion:*' use-cache true
        zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/completion-cache"

        # Directory completion
        zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
        zstyle ':completion:*' special-dirs true

        # Process completion
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

        # SSH/SCP completion
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback localhost broadcasthost
      '')

      # --- FZF-Tab Plugin Configuration (order 250) -------------------------
      (lib.mkOrder 250 ''
        # Load fzf-tab plugin - must come after compinit but before other plugins
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

        # Configure fzf-tab appearance and behavior
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null'
        zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
        zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
        zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --graph --color=always $word'
        zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --stat --color=always $word'
        zstyle ':fzf-tab:*' switch-group '<' '>'  # Switch between groups with < and >
        zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup  # Use tmux popup if in tmux
        zstyle ':fzf-tab:*' popup-pad 30 0  # Padding for tmux popup
      '')

      # --- Key Bindings (order 300) -----------------------------------------
      (lib.mkOrder 300 ''
        # History search
        bindkey '^P' history-substring-search-up
        bindkey '^N' history-substring-search-down
        bindkey '^[[A' history-search-backward  # Up arrow
        bindkey '^[[B' history-search-forward   # Down arrow

        # Word navigation
        bindkey '^[[1;5C' forward-word  # Ctrl+Right
        bindkey '^[[1;5D' backward-word # Ctrl+Left

        # Line navigation
        bindkey '^[[H' beginning-of-line # Home
        bindkey '^[[F' end-of-line       # End

        # Edit command in $EDITOR
        autoload -z edit-command-line
        zle -N edit-command-line
        bindkey '^X^E' edit-command-line
      '')

      # --- Essential Functions (order 400) ----------------------------------
      (lib.mkOrder 400 ''
        # Navigate to git root
        project-root() {
          cd "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null ||
          echo "Not in a git repository"
        }

        # Yazi shell wrapper with cd-on-quit
        y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
        }

        # WezTerm CLI helper
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

      # --- Environment Setup (order 500) ------------------------------------
      (lib.mkOrder 500 ''
        # PATH deduplication
        typeset -U path PATH

        # Context-aware optimizations
        [[ -n "$NVIM$VSCODE_PID" ]] && {
          zstyle ':completion:*' max-matches-width 0;
          zstyle ':completion:*' max-matches 10;
        }
        [[ -n "$SSH_CLIENT$SSH_TTY" ]] && {
          HISTSIZE=10000;
          SAVEHIST=10000;
        }
      '')

      # --- External Integrations (order 600) --------------------------------
      (lib.mkOrder 600 ''
        # 1Password CLI plugin
        [ -f "$HOME/.config/op/plugins.sh" ] && source "$HOME/.config/op/plugins.sh"

        # 1Password SSH agent
        ONEPASS_SOCKET="${myLib.secrets.opSSHSocket context}"
        [ -S "$ONEPASS_SOCKET" ] && export SSH_AUTH_SOCK="$ONEPASS_SOCKET"
        unset ONEPASS_SOCKET

        # TheFuck command correction - lazy loaded for performance
        if command -v thefuck >/dev/null 2>&1; then
          # Create wrapper function that loads thefuck on first use
          fuck() {
            # Remove the wrapper function
            unset -f fuck
            # Load thefuck aliases
            eval "$(thefuck --alias)"
            # Call the real fuck function with original arguments
            fuck "$@"
          }

          # Alternative alias
          fk() {
            # Remove the wrapper function
            unset -f fk
            # Load thefuck aliases
            eval "$(thefuck --alias fk)"
            # Call the real fk function with original arguments
            fk "$@"
          }
        fi

      '')

      # --- Development Environment (order 700) -------------------------------
      (lib.mkOrder 700 ''
        # Python virtual environment auto-activation
        autoload -U add-zsh-hook

        auto-venv() {
          if [[ -f ".venv/bin/activate" ]]; then
            source .venv/bin/activate
          elif [[ -n "$VIRTUAL_ENV" ]] && [[ ! -f ".venv/bin/activate" ]]; then
            deactivate 2>/dev/null || true
          fi
        }

        add-zsh-hook chpwd auto-venv
        auto-venv # Run on shell start

        # FZF Git integration - source from nix package
        [ -f "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh" ] && \
          source "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh"

        # FZF custom completion functions
        # Custom FZF completion with context-aware previews
        _fzf_comprun() {
          local command=$1
          shift
          # Keep preview command local to this function to avoid global namespace pollution
          local file_or_dir_preview='if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'

          case "$command" in
            cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
            export|unset) fzf --preview "eval 'echo \$'{}'" "$@" ;;
            ssh)          fzf --preview 'dig {}' "$@" ;;
            *)            fzf --preview "$file_or_dir_preview" "$@" ;;
          esac
        }

        # FZF path and directory generators
        _fzf_compgen_path() {
          fd --hidden --strip-cwd-prefix --exclude .git . "$1"
        }

        _fzf_compgen_dir() {
          fd --type=d --hidden --strip-cwd-prefix --exclude .git . "$1"
        }

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

        # Python project setup helper
        pysetup() {
          [ -f "pyproject.toml" ] && { echo "pyproject.toml already exists"; return 1; }
          poetry init -n
          poetry add --group dev ruff pytest
          echo "Python project initialized with Poetry"
          echo "Virtual environment will be created in .venv/"
        }

        # Rust cache statistics
        ruscache() {
          command -v sccache &>/dev/null && { echo "Rust cache:"; sccache --show-stats; } || echo "sccache not available"
        }

        # --- Navigation Helpers ------------------------------------------------
        # Quick navigation functions that can't be simple aliases

        # Return to previous directory
        back() {
          cd "$OLDPWD"
        }

        # Go to git repository root
        root() {
          cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
        }

        # Create and enter a temporary directory
        tmp() {
          cd "$(mktemp -d)" && pwd
        }

        # HTTP server with configurable port
        serve-port() {
          python3 -m http.server "''${1:-8000}"
        }
      '')

      # --- Terminal Integration (order 800) ---------------------------------
      (lib.mkOrder 800 ''
        # WezTerm integration
        if [[ "$TERM_PROGRAM" == "WezTerm" ]] && [[ -z "$WEZTERM_SHELL_SKIP_ENV" ]]; then
          typeset -g __wezterm_prev_nix=""
          typeset -g __wezterm_prev_venv=""

          __wezterm_update_env() {
            local current_nix="''${IN_NIX_SHELL:-0}"
            local current_venv="''${VIRTUAL_ENV##*/}"

            if [[ "$current_nix" != "$__wezterm_prev_nix" ]]; then
              printf "\033]1337;SetUserVar=%s=%s\007" "WEZTERM_IN_NIX" "$(echo -n "$current_nix" | base64)"
              __wezterm_prev_nix="$current_nix"
            fi

            if [[ "$current_venv" != "$__wezterm_prev_venv" ]]; then
              printf "\033]1337;SetUserVar=%s=%s\007" "WEZTERM_VENV" "$(echo -n "$current_venv" | base64)"
              __wezterm_prev_venv="$current_venv"
            fi
          }

          add-zsh-hook chpwd __wezterm_update_env
          __wezterm_update_env # Initial call
        fi
      '')

      # --- User Customizations (order 9000) ---------------------------------
      (lib.mkOrder 9000 ''
        # Source local customizations
        [ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
      '')
    ];
  };
}
