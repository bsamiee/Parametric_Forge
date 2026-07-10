# Title         : fzf.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/fzf.nix
# ----------------------------------------------------------------------------
# FZF configuration themed from the estate palette owner

{config, ...}: let
  inherit (config.forge.theme) palette;
in {
  programs.fzf = {
    enable = true;
    enableZshIntegration = false; # Manual init in zsh/init.nix (before Atuin for proper Ctrl+R)
    tmux.enableShellIntegration = false;

    # --- [DEFAULT_CONFIGURATION]
    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    defaultOptions = [
      "--color=fg:${palette.foreground.hex},fg+:${palette.background.hex},bg:${palette.background.hex},bg+:${palette.cyan.hex},selected-fg:${palette.background.hex},selected-bg:${palette.cyan.hex}"
      "--color=hl:${palette.green.hex},hl+:${palette.magenta.hex},info:${palette.comment.hex},marker:${palette.green.hex}"
      "--color=prompt:${palette.magenta.hex},spinner:${palette.green.hex},pointer:${palette.magenta.hex},header:${palette.comment.hex}"
      "--color=gutter:${palette.background.hex},border:${palette.cyan.hex},separator:${palette.pink.hex},scrollbar:${palette.pink.hex}"
      "--color=preview-fg:${palette.foreground.hex},preview-scrollbar:${palette.pink.hex},label:${palette.magenta.hex},query:${palette.foreground.hex}"
      "--border=sharp"
      # Border labels are widget-scoped below; forgit rows carry theirs in environments/shell.nix.
      "--border-label-pos=0"
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
      command = "fd --type f --hidden --follow --exclude .git";
      options = [
        "--border-label='[FILES]'"
        "--preview='bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || tree --level=2 --color=always --icons=always {}'"
      ];
    };

    # --- [ALT_C_DIRECTORY_NAVIGATION]
    changeDirWidget = {
      command = "fd --type d --hidden --follow --exclude .git";
      options = [
        "--border-label='[DIRECTORIES]'"
        "--preview='tree --level=2 --color=always --icons=always {}'"
      ];
    };

    # --- [CTRL_R_COMMAND_HISTORY]
    historyWidget.options = []; # Ctrl-R history disabled — Atuin owns it
  };
}
