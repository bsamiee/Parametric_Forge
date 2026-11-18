{
  lib,
  pkgs,
  theme,
  ...
}: let
  inherit (theme) roles;
  sgr = c: "\\e[38;2;${toString c.r};${toString c.g};${toString c.b}m";
in {
  home.packages = [pkgs.zsh-forgit];

  # --- [FORGIT]
  home.sessionVariables = {
    FORGIT_ADD_FZF_OPTS = "--border-label='[GIT ADD]'";
    FORGIT_DIFF_FZF_OPTS = "--border-label='[GIT DIFF]'";
    FORGIT_LOG_FZF_OPTS = "--border-label='[GIT LOG]'";
    FORGIT_RESET_HEAD_FZF_OPTS = "--border-label='[GIT RESET]'";
    FORGIT_CHECKOUT_FILE_FZF_OPTS = "--border-label='[GIT CHECKOUT]'";
    FORGIT_STASH_FZF_OPTS = "--border-label='[GIT STASH]'";
    FORGIT_CHERRY_PICK_FZF_OPTS = "--border-label='[GIT CHERRY-PICK]'";
    FORGIT_REBASE_FZF_OPTS = "--border-label='[GIT REBASE]'";
    FORGIT_FIXUP_FZF_OPTS = "--border-label='[GIT FIXUP]'";
    FORGIT_FZF_DEFAULT_OPTS = ''
      --height=80%
      --preview-window=right:60%:border-bold
    '';
  };

  programs.zsh = {
    siteFunctions = {
      gwt = ''
        (( $# )) && { git forgit worktree "$@"; return }
        local tree
        tree=$(git forgit worktree) || return
        [[ -d $tree ]] && builtin cd -- "$tree"
      '';
      gwa = ''
        local tree
        tree=$(git forgit worktree_add "$@") || return
        [[ -d $tree ]] || return 0
        builtin cd -- "$tree"
      '';
    };
    localVariables.YSU_MESSAGE_FORMAT = "${sgr roles.state.warning}Found existing %alias_type for ${sgr roles.accent.primary}\"%command\"${sgr roles.state.warning}. You should use: ${sgr roles.accent.primary}\"%alias\"\\e[0m";
    initContent = lib.mkOrder 950 ''
      source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
      add-zsh-hook -d preexec _check_global_aliases
    '';
  };
}
