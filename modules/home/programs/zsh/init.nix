# Title         : init.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/init.nix
# ----------------------------------------------------------------------------
# Interactive init rows outside a tool's own Home Manager integration: session secrets, fzf's completion hooks, the post-atuin suggestion
# override, mise activation last, and the transient prompt. Tool inits ride their HM orders: compinit 570, fzf-tab 580, autosuggestions 700,
# zoxide 851, fzf 910, plugins 950, starship/atuin/carapace/nix-index 1000, aliases 1100, syntax highlighting 1200.
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

      # --- [ZELLIJ_PANE_WEZTERM_IDENTITY]
      # A zellij server freezes its environment at creation and hands it to every pane, so after a WezTerm restart the inherited socket
      # (gui-sock-<gui pid>) and pane id are dead and `wezterm cli` spawns a stray mux server. Unset, the cli locates the live GUI instance
      # itself (documented resolution order) and targets its focused pane.
      if [[ -n $ZELLIJ ]]; then
        unset WEZTERM_UNIX_SOCKET WEZTERM_PANE
      fi

      # --- [FZF_COMPGEN_PATH_DIR]
      # fzf's documented hooks for ** completion: fd honors the ignore estate where fzf's built-in walker would not. The store path is a
      # Nix-side dependency of these hooks; fd is on no PATH outside a project.
      _fzf_compgen_path() {
        ${lib.getExe pkgs.fd} --hidden --follow --exclude .git . "$1"
      }

      _fzf_compgen_dir() {
        ${lib.getExe pkgs.fd} --type d --hidden --follow --exclude .git . "$1"
      }
    '')

    (lib.mkOrder 1010 ''
      # --- [SUGGESTION_SOURCE]
      # `atuin init zsh` prepends its own strategy to ZSH_AUTOSUGGEST_STRATEGY and documents overriding it after the init line: Atuin owns
      # Ctrl-R and up-arrow, inline suggestions stay on zsh's native history; async fetching is disabled the documented way, after the plugin sources.
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

    (lib.mkOrder 2000 ''
      # --- [MISE_ACTIVATE]
      # Last line of the interactive config: mise documents that PATH edits made after activation outrank the tools it manages
      # (settings, activate_aggressive), so nothing follows this hook.
      eval "$(${lib.getExe config.programs.mise.package} activate zsh)"
    '')
  ];
}
