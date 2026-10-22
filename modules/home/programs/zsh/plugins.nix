# Title         : plugins.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/plugins.nix
# ----------------------------------------------------------------------------
# Sourced plugin surface: forgit's git subcommand on the profile with the two worktree commands that cd as site functions, and alias coaching
# deferred past the first prompt. Widget-order-bound surfaces live elsewhere: fzf-tab and zsh-completions in completions.nix, autosuggestions
# and syntax highlighting in options.nix.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) roles;
  sgr = c: "\\e[38;2;${toString c.r};${toString c.g};${toString c.b}m";
in {
  # git-forgit and its _git-forgit completion ride the profile; every FORGIT_*_FZF_OPTS row stays an env read by git-forgit itself.
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
    # you-should-use registers only a preexec hook, so it loads at the first zle idle (zsh-defer) and its five tput forks leave the prompt path.
    localVariables.YSU_MESSAGE_FORMAT = "${sgr roles.state.warning}Found existing %alias_type for ${sgr roles.accent.primary}\"%command\"${sgr roles.state.warning}. You should use: ${sgr roles.accent.primary}\"%alias\"\\e[0m";
    initContent = lib.mkOrder 950 ''
      source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh
      zsh-defer source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
    '';
  };
}
