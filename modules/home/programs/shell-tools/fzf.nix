# Title         : fzf.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/fzf.nix
# ----------------------------------------------------------------------------
# FZF configuration with proper integration

{ config, lib, pkgs, ... }:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;  # Let home-manager handle base integration
    tmux.enableShellIntegration = false;

    # --- Default configuration ----------------------------------------------
    defaultCommand = "fd --type f --hidden --follow --exclude .git";

    defaultOptions = [
      # Colors - Dracula theme
      "--color=fg:#44475a,fg+:#F8F8F2,bg:#15131F,bg+:#44475a"
      "--color=hl:#94F2E8,hl+:#d82f94,info:#7A71AA,marker:#50FA7B"
      "--color=prompt:#d82f94,spinner:#50FA7B,pointer:#d82f94,header:#7A71AA"
      "--color=gutter:#15131F,border:#94F2E8,separator:#E98FBE,scrollbar:#E98FBE"
      "--color=preview-fg:#F8F8F2,preview-scrollbar:#E98FBE,label:#d82f94,query:#F8F8F2"
      # Border and styling
      "--border=sharp"
      # Note: Border label set per-command in init.nix and shell.nix
      "--border-label-pos=0"
      "--preview-window=border-bold"
      # UI elements
      "--prompt='> '"
      "--marker='>'"
      "--pointer='◆'"
      "--separator='─'"
      "--scrollbar='│'"
      "--info=right"
      # Behavior
      "--height=60%"
      "--layout=reverse"
      "--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || eza --tree --level=2 --color=always {}'"
      "--preview-window=right:50%:border-bold"
      "--bind=ctrl-u:preview-page-up"
      "--bind=ctrl-d:preview-page-down"
    ];

    # --- Ctrl-T: File selection ---------------------------------------------
    fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidgetOptions = [
      "--border-label='[FILES]'"
    ];

    # --- Alt-C: Directory navigation ----------------------------------------
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [
      "--border-label='[DIRECTORIES]'"
      "--preview='eza --tree --level=2 --color=always {}'"
    ];

    # --- Ctrl-R: Command history --------------------------------------------
    # Note: Ctrl-R (history) disabled - handled by Atuin
    historyWidgetOptions = [];
  };
}
