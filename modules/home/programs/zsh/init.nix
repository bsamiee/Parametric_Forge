# Title         : init.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/init.nix
# ----------------------------------------------------------------------------
# Interactive init: session secrets, tool widget wiring, final widget ordering. Completion surface lives in completions.nix; roster in plugins.nix.
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

      # --- [FZF_PATH_DIR_GENERATORS_FZF_COMPLETION_TRIGGER]
      _fzf_compgen_path() {
        fd --hidden --follow --exclude .git . "$1"
      }

      _fzf_compgen_dir() {
        fd --type d --hidden --follow --exclude .git . "$1"
      }

      # --- [TOOL_INTEGRATION]
      eval "$(${pkgs.bat-extras.batman}/bin/batman --export-env)"

      # Alias tools to full paths for generated init scripts that call them by name
      alias atuin="${pkgs.atuin}/bin/atuin"
      alias zoxide="${pkgs.zoxide}/bin/zoxide"

    '')

    (lib.mkOrder 650 ''
      # --- [FZF_KEYBINDINGS_SUPPRESS_READ_ONLY_OPTION_ERRORS]
      # FZF restores the read-only 'zle' option and emits harmless errors, so stderr is suppressed; keybindings still register. fzf captures the
      # fzf-tab ^I widget as fzf_default_completion, so plain Tab falls through to fzf-tab and the ** trigger keeps fzf path completion.
      if [[ $options[zle] = on ]]; then
        source <(fzf --zsh) 2>/dev/null
      fi
    '')

    (lib.mkOrder 720 ''
      # --- [ATUIN_HISTORY_INITIALIZATION_AFTER_AUTOSUGGESTIONS_SOURCE_AT_700]
      if [[ $options[zle] = on ]]; then
        eval "$(${pkgs.atuin}/bin/atuin init zsh)"
      fi
    '')

    (lib.mkOrder 730 ''
      # Final strategy owner: atuin init self-prepends "atuin", so this assignment is the deterministic end state after all widget wrappers source.
      typeset -ga ZSH_AUTOSUGGEST_STRATEGY
      ZSH_AUTOSUGGEST_STRATEGY=(atuin completion)
    '')
  ];
}
