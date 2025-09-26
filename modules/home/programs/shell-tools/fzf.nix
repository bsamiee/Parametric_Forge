# Title         : fzf.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/fzf.nix
# ----------------------------------------------------------------------------
# Fuzzy finder configuration - theme handled by Stylix

{ config, lib, pkgs, ... }:

let
  # Common exclusions for file/directory searches
  excludePatterns = ".git,.svn,node_modules,target,dist,build,.DS_Store";
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;
    tmux.enableShellIntegration = false;

    # Stylix will set programs.fzf.colors automatically when autoEnable = true
    # These colors come from config.stylix.base16Scheme in theme.nix

    # --- Core Settings ------------------------------------------------------
    defaultCommand = "fd --type f --hidden --follow --exclude={${excludePatterns}}";

    defaultOptions = [
      # Layout and display
      "--height=60%"
      "--min-height=20"
      "--layout=reverse"
      "--border=rounded"
      "--border-label='[ FZF ]'"
      "--border-label-pos=3"
      "--padding=1"
      "--margin=0,2"
      "--info=inline:'< '"

      # Search behavior
      "--ansi"                 # Process ANSI color codes
      "--tabstop=4"            # Tab width
      "--cycle"                # Cycle through results
      "--keep-right"           # Keep right side of long lines visible
      "--exit-0"               # Exit if no match
      "--select-1"             # Auto-select if only one match

      # Results display
      "--prompt='❯ '"
      "--pointer='▶'"
      "--marker='✓'"
      "--scrollbar='│'"

      # Preview window defaults
      "--preview-window=right:50%:border-left:wrap"
      "--preview-label='[ Preview ]'"
      "--preview-label-pos=2"

      # Keybindings for common actions
      "--bind=ctrl-/:toggle-preview"
      "--bind=ctrl-a:select-all"
      "--bind=ctrl-d:deselect-all"
      "--bind=ctrl-y:preview-up"
      "--bind=ctrl-e:preview-down"
      "--bind=ctrl-b:preview-page-up"
      "--bind=ctrl-f:preview-page-down"
      "--bind=ctrl-u:preview-half-page-up"
      "--bind=ctrl-n:preview-half-page-down"
      "--bind=alt-w:toggle-preview-wrap"
      "--bind=shift-up:preview-up"
      "--bind=shift-down:preview-down"
    ];

    # --- Widget: File Search (Ctrl+T) ---------------------------------------
    fileWidgetCommand = "fd --type f --type l --hidden --follow --exclude={${excludePatterns}}";
    fileWidgetOptions = [
      "--prompt='Files❯ '"
      "--border-label='[ Files ]'"
      "--border-label-pos=3"
      "--header='CTRL-O (open) | CTRL-Y (copy path)'"
      "--preview='([[ -f {} ]] && (bat --line-range=:500 {} || cat {})) || ([[ -d {} ]] && eza {}) || echo {} 2> /dev/null | head -200'"
      "--bind='ctrl-o:execute(open {} &> /dev/tty)'"
      "--bind='ctrl-y:execute-silent(echo -n {} | pbcopy)'"
    ];

    # --- Widget: Directory Navigation (Alt+C) -------------------------------
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude={${excludePatterns}}";
    changeDirWidgetOptions = [
      "--prompt='Dirs❯ '"
      "--border-label='[ Directories ]'"
      "--border-label-pos=3"
      "--header='CTRL-O (open finder) | CTRL-Y (copy path)'"
      "--preview='eza {}'"
      "--bind='ctrl-o:execute(open {} &> /dev/tty)'"
      "--bind='ctrl-y:execute-silent(echo -n {} | pbcopy)'"
    ];
  };
}
