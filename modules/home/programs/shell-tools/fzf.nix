# Title         : fzf.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/fzf.nix
# ----------------------------------------------------------------------------
# FZF configuration themed from the estate palette owner
{config, ...}: let
  inherit (config.forge.theme) palette;
in {
  programs.fzf = {
    enable = true;
    enableZshIntegration = false; # Manual init in zsh/init.nix (before Atuin for proper Ctrl+R)
    tmux.enableShellIntegration = false;

    # --- Default Configuration ----------------------------------------------
    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    defaultOptions = [
      # Colors from the shared palette tokens
      "--color=fg:${palette.foreground.hex},fg+:${palette.background.hex},bg:${palette.background.hex},bg+:${palette.cyan.hex},selected-fg:${palette.background.hex},selected-bg:${palette.cyan.hex}"
      "--color=hl:${palette.green.hex},hl+:${palette.magenta.hex},info:${palette.comment.hex},marker:${palette.green.hex}"
      "--color=prompt:${palette.magenta.hex},spinner:${palette.green.hex},pointer:${palette.magenta.hex},header:${palette.comment.hex}"
      "--color=gutter:${palette.background.hex},border:${palette.cyan.hex},separator:${palette.pink.hex},scrollbar:${palette.pink.hex}"
      "--color=preview-fg:${palette.foreground.hex},preview-scrollbar:${palette.pink.hex},label:${palette.magenta.hex},query:${palette.foreground.hex}"
      # Border and styling
      "--border=sharp"
      # Note: Border label set per-command in init.nix and shell.nix
      "--border-label-pos=0"
      # UI elements
      "--prompt='󰅂 '"
      "--marker='✓'"
      "--pointer='❯'"
      "--separator='─'"
      "--scrollbar='│'"
      "--info=right"
      # Behavior; previews are widget-scoped, never a global default
      "--height=80%"
      "--layout=reverse"
      "--preview-window=right:50%:border-bold"
      "--bind=ctrl-k:preview-page-up"
      "--bind=ctrl-j:preview-page-down"
    ];

    # --- Ctrl-T: File Selection ---------------------------------------------
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--border-label='[FILES]'"
      "--preview='bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || tree --level=2 --color=always --icons=always {}'"
    ];

    # --- Alt-C: Directory Navigation ----------------------------------------
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--border-label='[DIRECTORIES]'"
      "--preview='tree --level=2 --color=always --icons=always {}'"
    ];

    # --- Ctrl-R: Command History --------------------------------------------
    # Note: Ctrl-R (history) disabled - handled by Atuin
    historyWidgetOptions = [];
  };
}
