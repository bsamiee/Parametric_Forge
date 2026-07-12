# Title         : init.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/init.nix
# ----------------------------------------------------------------------------
# Interactive init: session secrets, tool widget wiring, final widget ordering.
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkBefore ''
      # --- [SESSION_SECRETS]
      [[ ! -f "${config.xdg.configHome}/forge-session-secrets.sh" ]] || source "${config.xdg.configHome}/forge-session-secrets.sh"

      # --- [FZF_COMPGEN_PATH_DIR]
      _fzf_compgen_path() {
        fd --hidden --follow --exclude .git . "$1"
      }

      _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude .git . "$1"
      }

      # --- [TOOL_INTEGRATION]
      # Atuin's generated init calls `atuin` by bare name; the alias pins it to the store path. Zoxide needs no twin — its HM integration
      # emits full-path init itself. batman MANPAGER/MANROFFOPT are static session-env rows, so no per-shell export-env fork.
      alias atuin="${pkgs.atuin}/bin/atuin"

    '')

    (lib.mkOrder 650 ''
      # --- [FZF_KEYBINDINGS]
      # FZF restores the read-only 'zle' option and emits harmless errors, so stderr is suppressed; keybindings still register. fzf captures the
      # fzf-tab ^I widget as fzf_default_completion, so plain Tab falls through to fzf-tab and the ** trigger keeps fzf path completion.
      if [[ $options[zle] = on ]]; then
        source <(fzf --zsh) 2>/dev/null
      fi
    '')

    (lib.mkOrder 720 ''
      # --- [ATUIN_HISTORY_INIT]
      if [[ $options[zle] = on ]]; then
        eval "$(${pkgs.atuin}/bin/atuin init zsh)"
      fi
    '')

    (lib.mkOrder 730 ''
      # Atuin remains the Ctrl-R/up-arrow history owner; inline suggestions use zsh-native synchronous history after every widget wrapper sources.
      typeset -ga ZSH_AUTOSUGGEST_STRATEGY
      ZSH_AUTOSUGGEST_STRATEGY=(history)
      unset ZSH_AUTOSUGGEST_USE_ASYNC
    '')

    (lib.mkOrder 1500 ''
      # --- [TRANSIENT_PROMPT]
      # Collapses accepted or interrupted lines to HH:MM + pointer without another Starship render.
      if [[ $PROMPT == *starship* ]]; then
        autoload -Uz add-zsh-hook add-zle-hook-widget
        typeset -g _forge_prompt_live="$PROMPT"
        typeset -gi _forge_prompt_status=0
        _forge-transient-save() {
          TRAPINT() { _forge-transient-apply; return $(( 128 + $1 )) }
          PROMPT="$_forge_prompt_live"
          _forge_prompt_status=''${STARSHIP_CMD_STATUS:-0}
        }
        _forge-transient-apply() {
          if zle; then
            local pointer=❯ pointer_color
            if [[ $KEYMAP == vicmd ]]; then
              pointer=❮
              pointer_color="${config.forge.theme.roles.state.success.hex}"
            elif (( _forge_prompt_status == 0 )); then
              pointer_color="${config.forge.theme.roles.state.success.hex}"
            else
              pointer_color="${config.forge.theme.roles.state.danger.hex}"
            fi
            PROMPT="%F{${config.forge.theme.roles.text.muted.hex}}%D{%H:%M}%f %B%F{''${pointer_color}}''${pointer}%f%b "
            zle .reset-prompt
          fi
        }
        add-zsh-hook precmd _forge-transient-save
        add-zle-hook-widget zle-line-finish _forge-transient-apply
      fi
    '')
  ];
}
