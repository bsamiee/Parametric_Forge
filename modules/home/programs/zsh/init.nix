{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh.initContent = lib.mkMerge [
    (lib.mkBefore ''
      # --- [FZF_COMPGEN_PATH_DIR]
      _fzf_compgen_path() {
        ${lib.getExe pkgs.fd} --hidden --follow --exclude .git . "$1"
      }

      _fzf_compgen_dir() {
        ${lib.getExe pkgs.fd} --type d --hidden --follow --exclude .git . "$1"
      }
    '')

    (lib.mkOrder 1010 ''
      # --- [SUGGESTION_SOURCE]
      ZSH_AUTOSUGGEST_STRATEGY=(history)
      unset ZSH_AUTOSUGGEST_USE_ASYNC
    '')

    (lib.mkOrder 1500 ''
      # --- [TRANSIENT_PROMPT]
      if [[ $PROMPT == *starship* ]]; then
        autoload -Uz add-zsh-hook add-zle-hook-widget
        typeset -gi _transient_prompt_status=0
        _transient-prompt-save() {
          TRAPINT() { _transient-prompt-apply; return $(( 128 + $1 )) }
          _transient_prompt_status=''${STARSHIP_CMD_STATUS:-0}
        }
        _transient-prompt-apply() {
          if zle; then
            local pointer=❯ pointer_color
            if [[ $KEYMAP == vicmd ]]; then
              pointer=❮
              pointer_color="${config.forge.theme.roles.state.success.hex}"
            elif (( _transient_prompt_status == 0 )); then
              pointer_color="${config.forge.theme.roles.state.success.hex}"
            else
              pointer_color="${config.forge.theme.roles.state.danger.hex}"
            fi
            local PROMPT="%F{${config.forge.theme.roles.text.muted.hex}}%D{${config.forge.theme.projections.timeDisplay.sameDay}}%f %B%F{''${pointer_color}}''${pointer}%f%b "
            zle .reset-prompt
          fi
        }
        add-zsh-hook precmd _transient-prompt-save
        add-zle-hook-widget zle-line-finish _transient-prompt-apply
      fi
    '')

    (lib.mkOrder 1900 ''
      # --- [TERMINAL_MARKS]
      autoload -Uz add-zsh-hook
      typeset -U precmd_functions preexec_functions
      typeset -gi _terminal_command=0
      _terminal-encode() {
        local LC_ALL=C char
        REPLY=
        for char in ''${(s::)1}; do
          [[ $char == [[:alnum:]/._~-] ]] && REPLY+=$char || REPLY+=%''${(l:2::0:)$(( [##16] #char ))}
        done
      }
      _terminal-marks-precmd() {
        local code=$?
        (( _terminal_command )) && print -n "\e]133;D;$code\a"
        _terminal_command=0
        _terminal-encode $PWD
        print -n "\e]7;file://$HOST$REPLY\a"
      }
      _terminal-marks-preexec() {
        _terminal_command=1
        _terminal-encode $1
        print -n "\e]133;C;cmdline_url=$REPLY\a"
      }
      add-zsh-hook precmd _terminal-marks-precmd
      add-zsh-hook preexec _terminal-marks-preexec
      PROMPT=$'%{\e]133;A;k=i\a%}'$PROMPT$'%{\e]133;B\a%}'
      RPROMPT=
    '')

    (lib.mkOrder 2000 ''
      # --- [MISE_ACTIVATE]
      [[ -n $VSCODE_RESOLVING_ENVIRONMENT ]] || eval "$(${lib.getExe config.programs.mise.package} activate zsh)"
    '')
  ];
}
