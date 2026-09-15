# Title         : fzf.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/fzf.nix
# ----------------------------------------------------------------------------
# FZF configuration themed from the estate palette owner
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) projections;
  # fd rides its store path: a Nix-side dependency of the fzf widgets, on no PATH outside a project.
  fd = lib.getExe pkgs.fd;
  fdFiles = "${fd} --type f --hidden --follow --exclude .git";
in {
  programs.fzf = {
    enable = true;
    # HM sources `fzf --zsh` at order 910: after fzf-tab (580), so ^I keeps fzf-tab behind the ** trigger, and before atuin (1000).
    enableZshIntegration = true;

    # --- [DEFAULT_CONFIGURATION]
    defaultCommand = fdFiles;

    # Color rows come from the theme owner's shared fzf vocabulary; every other fzf-embedding surface consumes the same rows.
    defaultOptions =
      projections.fzfColorRows
      ++ [
        "--border=sharp"
        # Border labels are widget-scoped below; forgit rows carry theirs in environments/shell.nix.
        # UI elements: BMP-only glyphs — PUA codepoints fail fzf width validation
        "--prompt='❯ '"
        "--marker='✓'"
        "--pointer='❯'"
        "--separator='─'"
        "--scrollbar=│" # unquoted: quote chars would survive FZF_DEFAULT_OPTS re-split and trip fzf's 1-2 char scrollbar validation
        "--info=right"
        "--highlight-line"
        # Previews are widget-scoped, never a global default
        "--height=80%"
        "--layout=reverse"
        "--preview-window=right:50%:border-bold"
        "--bind=ctrl-k:preview-page-up"
        "--bind=ctrl-j:preview-page-down"
      ];

    # --- [CTRL_T_FILE_SELECTION]
    fileWidget = {
      command = fdFiles;
      options = [
        "--border-label='[FILES]'"
        "--preview='bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || tree --level=2 --color=always --icons=always {}'"
      ];
    };

    # --- [ALT_C_DIRECTORY_NAVIGATION]
    changeDirWidget = {
      command = "${fd} --type d --hidden --follow --exclude .git";
      options = [
        "--border-label='[DIRECTORIES]'"
        "--preview='tree --level=2 --color=always --icons=always {}'"
      ];
    };

    # --- [CTRL_R_OWNER]
    # An empty history command exports FZF_CTRL_R_COMMAND="" ahead of `fzf --zsh`, whose documented opt-out skips the ^R binding: Atuin is the
    # one owner of history search instead of rebinding over fzf.
    historyWidget.command = "";
  };
}
