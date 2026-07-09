# Title         : init.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/init.nix
# ----------------------------------------------------------------------------
# Interactive init: session secrets, tool widget wiring, and final widget
# ordering. Completion surface lives in completions.nix; roster in plugins.nix.
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkBefore ''
      # --- Session secrets (backend-dispatched; owner: shell-tools/1password.nix) --
      [[ ! -f "${config.xdg.configHome}/forge-session-secrets.sh" ]] || source "${config.xdg.configHome}/forge-session-secrets.sh"

      # --- FZF path/dir generators (fzf ** completion trigger) ---------------------
      _fzf_compgen_path() {
        fd --hidden --follow --exclude .git . "$1"
      }

      _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude .git . "$1"
      }

      # --- Tool Integration -------------------------------------------------------
      # Batman man page integration
      eval "$(${pkgs.bat-extras.batman}/bin/batman --export-env)"

      # Note: pnpm installed via nix (node-tools.nix) for PATH stability across all processes
      # Note: 1Password Shell Plugins (gh, aws, etc.) handled by programs._1password-shell-plugins
      # Note: SSH agent configured via ssh.nix IdentityAgent directive

      # Alias tools to full paths for generated init scripts that call them by name
      alias atuin="${pkgs.atuin}/bin/atuin"
      alias zoxide="${pkgs.zoxide}/bin/zoxide"

    '')

    (lib.mkOrder 650 ''
      # --- FZF Keybindings (suppress read-only option errors) --------------------
      # FZF tries to restore the read-only 'zle' option, causing harmless errors.
      # Suppress stderr to keep output clean; FZF keybindings still register.
      # fzf captures the fzf-tab ^I widget as fzf_default_completion: plain Tab
      # falls through to fzf-tab, the ** trigger keeps fzf path completion.
      if [[ $options[zle] = on ]]; then
        source <(fzf --zsh) 2>/dev/null
      fi
    '')

    (lib.mkOrder 720 ''
      # --- Atuin History Initialization (after autosuggestions source at 700) ----
      if [[ $options[zle] = on ]]; then
        eval "$(${pkgs.atuin}/bin/atuin init zsh)"
      fi
    '')

    (lib.mkOrder 730 ''
      # Final strategy owner: atuin init self-prepends "atuin"; this assignment is
      # the deterministic end state after all widget wrappers have sourced.
      typeset -ga ZSH_AUTOSUGGEST_STRATEGY
      ZSH_AUTOSUGGEST_STRATEGY=(atuin completion)
    '')
  ];
}
