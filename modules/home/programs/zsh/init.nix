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
      # --- FZF Configuration ------------------------------------------------
      # Custom completion functions
      _fzf_compgen_path() {
        fd --hidden --follow --exclude .git . "$1"
      }

      _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude .git . "$1"
      }

      # fzf-tab configuration
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
      zstyle ':fzf-tab:*' switch-group ',' '.'

      # --- Tool Integration -------------------------------------------------
      # Batman man page integration
      eval "$(${pkgs.bat-extras.batman}/bin/batman --export-env)"
    '')

    (lib.mkOrder 550 ''
      # --- Completion zstyle configuration ----------------------------------
      zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
      zstyle ':completion:*' use-cache true
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
      zstyle ':completion:*' menu no
      zstyle ':completion:*:descriptions' format '[%d]'
    '')

    ''
      # --- Shell Options ----------------------------------------------------
      # These run after everything
      setopt AUTO_PUSHD PUSHD_IGNORE_DUPS CDABLE_VARS

      # time replacement - use hyperfine with args, builtin without
      time() {
        if [ $# -eq 0 ]; then
          command time
        else
          hyperfine "$@"
        fi
      }

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
