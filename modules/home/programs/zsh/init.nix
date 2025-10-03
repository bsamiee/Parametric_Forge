# Title         : init.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/init.nix
# ----------------------------------------------------------------------------
# Zsh initialization - configuration only, plugins loaded by home-manager

{ config, lib, pkgs, ... }:

{
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkBefore ''
      # --- Completion cache -------------------------------------------------------
      command mkdir -p -- "${config.xdg.cacheHome}/zsh"
      export ZSH_COMPDUMP="${config.xdg.cacheHome}/zsh/zcompdump-''${ZSH_VERSION}"

      # --- FZF Configuration ------------------------------------------------------
      # Custom completion functions
      _fzf_compgen_path() {
        fd --hidden --follow --exclude .git . "$1"
      }

      _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude .git . "$1"
      }

      # --- Tool Integration -------------------------------------------------------
      # Batman man page integration
      eval "$(${pkgs.bat-extras.batman}/bin/batman --export-env)"

      # 1Password CLI plugins (for AWS, GitHub CLI, etc.)
      [ -f "$HOME/.config/op/plugins.sh" ] && source "$HOME/.config/op/plugins.sh"

      # 1Password SSH agent socket
      OP_SSH_SOCK="$HOME/.1password/agent.sock"
      [ -S "$OP_SSH_SOCK" ] && export SSH_AUTH_SOCK="$OP_SSH_SOCK"
      unset OP_SSH_SOCK

    '')

    (lib.mkOrder 400 ''
      # --- Custom Completions (before compinit) -----------------------------------
      # Add custom completions directory to fpath
      mkdir -p "${config.xdg.dataHome}/zsh/completions"
      fpath=("${config.xdg.dataHome}/zsh/completions" $fpath)

      # Generate native completions for tools not covered by carapace
      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_zellij" ]]; then
        ${pkgs.zellij}/bin/zellij setup --generate-completion zsh > "${config.xdg.dataHome}/zsh/completions/_zellij"
      fi

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_wezterm" ]]; then
        wezterm shell-completion --shell zsh > "${config.xdg.dataHome}/zsh/completions/_wezterm"
      fi

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_starship" ]]; then
        ${pkgs.starship}/bin/starship completions zsh > "${config.xdg.dataHome}/zsh/completions/_starship"
      fi

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_atuin" ]]; then
        ${pkgs.atuin}/bin/atuin gen-completions --shell zsh > "${config.xdg.dataHome}/zsh/completions/_atuin"
      fi

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_gh" ]]; then
        ${pkgs.gh}/bin/gh completion -s zsh > "${config.xdg.dataHome}/zsh/completions/_gh"
      fi

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_rclone" ]]; then
        ${pkgs.rclone}/bin/rclone completion zsh - > "${config.xdg.dataHome}/zsh/completions/_rclone"
      fi

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_op" ]]; then
        ${pkgs._1password-cli}/bin/op completion zsh > "${config.xdg.dataHome}/zsh/completions/_op"
      fi
    '')

    (lib.mkOrder 550 ''
      # --- Completion zstyle configuration ----------------------------------------
      zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
      zstyle ':completion:*' use-cache true
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
      zstyle ':completion:*' menu no
      zstyle ':completion:*:descriptions' format '[%d]'
    '')

    (lib.mkOrder 600 ''
      # --- fzf-tab configuration (after carapace loads) ---------------------------
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ':fzf-tab:*' fzf-flags --height=80%  # Explicitly set height (not inherited)
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
      zstyle ':fzf-tab:*' switch-group ',' '.'
    '')

    ''
      # --- Shell Options ----------------------------------------------------------
      # These run after everything
      setopt AUTO_PUSHD PUSHD_IGNORE_DUPS CDABLE_VARS

      # npm wrapper - use pnpm by default, real npm for legacy projects
      npm() {
        if [[ -f package-lock.json ]]; then
          command npm "$@"
        else
          pnpm "$@"
        fi
      }

      # Yazi shell wrapper - cd on quit
      y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    ''
  ];
}
