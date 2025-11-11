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

      # Transparent GitHub CLI wrapper that hydrates tokens via 1Password
      if command -v gh >/dev/null 2>&1; then
        gh() {
          local gh_bin
          if ! gh_bin="$(whence -p gh)"; then
            printf 'parametric-forge: unable to locate gh binary on PATH\n' >&2
            return 127
          fi

          local op_template="''${OP_ENV_TEMPLATE:-$HOME/.config/op/env.template}"
          local gh_config_dir="''${GH_CONFIG_DIR:-''${XDG_CONFIG_HOME:-$HOME/.config}/gh}"
          local gh_hosts="$gh_config_dir/hosts.yml"
          local prefer_native=0

          # Always use the native gh authentication flow for auth subcommands.
          if [[ "$1" == "auth" ]]; then
            case "''${2:-}" in
              login|logout|status|refresh|setup-git|token)
                prefer_native=1
                ;;
            esac
          fi

          # If gh already has a stored OAuth token, keep using it unless forced.
          if [[ -f "$gh_hosts" ]]; then
            prefer_native=1
          fi

          # Manual overrides for edge cases.
          if [[ "''${GH_FORCE_OP_TOKEN:-0}" == "1" ]]; then
            prefer_native=0
          elif [[ "''${GH_BYPASS_OP:-0}" == "1" ]]; then
            prefer_native=1
          fi

          if (( prefer_native )); then
            "$gh_bin" "$@"
            return $?
          fi

          if command -v op >/dev/null 2>&1 \
             && [[ -n "$op_template" ]] \
             && [[ -f "$op_template" ]]; then
            op run --env-file "$op_template" -- "$gh_bin" "$@"
          else
            "$gh_bin" "$@"
          fi
        }
      fi

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

      if [[ ! -f "${config.xdg.dataHome}/zsh/completions/_atuin" ]]; then
        ${pkgs.atuin}/bin/atuin gen-completions --shell zsh > "${config.xdg.dataHome}/zsh/completions/_atuin"
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
      zstyle ':completion:*:git:*' group-name '''
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':carapace:*' nospace true  # Better spacing behavior
    '')

    (lib.mkOrder 600 ''
      # --- fzf-tab configuration (after carapace loads) ---------------------------
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ':fzf-tab:*' fzf-pad 4
      zstyle ':fzf-tab:*' switch-group '<' '>'
      zstyle ':fzf-tab:*' fzf-flags --height=80%  # Explicitly set height (not inherited)
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps aux | grep -w $word'
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'systemctl status $word'
    '')

    ''
      # --- Shell Options (these run after everything) -----------------------------
      setopt AUTO_PUSHD PUSHD_IGNORE_DUPS CDABLE_VARS

      # npm wrapper - use pnpm by default, real npm for legacy projects
      npm() {
        if [[ -f package-lock.json ]]; then
          command npm "$@"
        else
          pnpm "$@"
        fi
      }

    ''
  ];
}
