# Title         : plugins.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/zsh/plugins.nix
# ----------------------------------------------------------------------------
# Sourced-plugin roster: HM sources each row at order 950. Widget-order-bound surfaces live elsewhere by design: fzf-tab and zsh-completions belong to
# completions.nix (pre-wrapper / pre-compinit), autosuggestions and syntax highlighting to HM options in options.nix. A new sourced plugin is one row.
{
  config,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) roles;
  sgr = c: "\\e[38;2;${toString c.r};${toString c.g};${toString c.b}m";
in {
  programs.zsh = {
    plugins = [
      {
        # Its commands reach the shell through the alias register (aliases/git.nix, git-forgit rows), never its own alias table: seven of its
        # default names (ga gd gcp grb gbd gco grs) collide with register rows, and FORGIT_NO_ALIASES is the documented opt-out.
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

    # Pre-source knob you-should-use reads at load; the coaching line carries the warning and accent tiers of the theme as truecolor SGR.
    # forgit's own knobs are environment rows (environments/shell.nix): it warns on any config option it finds unexported.
    localVariables.YSU_MESSAGE_FORMAT = "${sgr roles.state.warning}Found existing %alias_type for ${sgr roles.accent.primary}\"%command\"${sgr roles.state.warning}. You should use: ${sgr roles.accent.primary}\"%alias\"\\e[0m";
  };
}
