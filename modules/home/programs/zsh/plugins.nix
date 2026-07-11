# Title         : plugins.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/plugins.nix
# ----------------------------------------------------------------------------
# Sourced-plugin roster: HM sources each row at order 900. Widget-order-bound surfaces live elsewhere by design: fzf-tab and zsh-completions belong to
# completions.nix (pre-wrapper / pre-compinit), autosuggestions and syntax highlighting to HM options in options.nix. A new sourced plugin is one row.
{pkgs, ...}: {
  programs.zsh.plugins = [
    {
      name = "forgit";
      src = pkgs.zsh-forgit;
      file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
    }
    {
      # Alias coaching kept deliberately: operator-ruled behavioral surface.
      name = "you-should-use";
      src = pkgs.zsh-you-should-use;
      file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
    }
  ];
}
