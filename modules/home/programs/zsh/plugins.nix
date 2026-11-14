{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) roles;
  sgr = c: "\\e[38;2;${toString c.r};${toString c.g};${toString c.b}m";
in {
  home.packages = [pkgs.zsh-forgit];

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
      source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh
      zsh-defer source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
    '';
  };
}
