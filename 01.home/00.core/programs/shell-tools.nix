# Title         : shell-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/shell-tools.nix
# ----------------------------------------------------------------------------
# Shell tool configuration - gradually rebuilding

{ pkgs, ... }:

{
  programs = {
    # --- Essential Development Tools ----------------------------------------

    # Direnv - Per-directory environment management (critical for Nix)
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };

    git = {
      enable = true;
    };

    ssh = {
      enable = true;
    };

    # --- Nix-specific Tools -------------------------------------------------

    # Nix Index - Command-not-found for Nix
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # --- Shell Enhancement Tools --------------------------------------------

    # Starship - Modern prompt with git/language awareness
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromTOML (builtins.readFile ../configs/apps/starship.toml); # Load config from our TOML file
    };

    # --- Modern CLI Tools ---------------------------------------------------

    jq = {
      enable = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    bottom = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ../configs/system/bottom/bottom.toml);
    };

    broot = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromTOML (builtins.readFile ../configs/system/broot/config.toml);
    };

    fd = {
      enable = true;
    };

    ripgrep = {
      enable = true;
    };

    bat = {
      enable = true;
    };

    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";

      # Dracula theme
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9"
        "--color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9"
        "--color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6"
        "--color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
      ];

      # CTRL-T: File selection widget
      fileWidgetCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
      fileWidgetOptions = [
        "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
      ];

      # ALT-C: Directory navigation widget
      changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
      changeDirWidgetOptions = [
        "--preview 'eza --tree --color=always {} | head -200'"
      ];

      # CTRL-R: History search widget
      historyWidgetOptions = [
        "--sort"
        "--exact"
      ];
    };
  };

  # --- Additional ZSH-related packages --------------------------------------
  home.packages = with pkgs; [
    fzf-git-sh # Git object browser powered by fzf
    zsh-fzf-tab # Replace zsh's tab completion with fzf
  ];
}
