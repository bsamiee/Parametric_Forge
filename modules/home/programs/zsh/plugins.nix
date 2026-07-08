# Title         : plugins.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/plugins.nix
# ----------------------------------------------------------------------------
# Zsh plugin management - home-manager native approach
{pkgs, ...}: {
  # fzf-tab is not listed here: HM sources plugins at order 900, after autosuggestions
  # wrap widgets. init.nix sources it at 580 (post-compinit, pre-wrappers) instead.
  programs.zsh.plugins = [
    {
      name = "forgit";
      src = pkgs.zsh-forgit;
      file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
    }
    {
      name = "you-should-use";
      src = pkgs.zsh-you-should-use;
      file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
    }
  ];
}
