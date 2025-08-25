# Title         : shell-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/shell-tools.nix
# ----------------------------------------------------------------------------
# Modern shell tool integrations and enhancements.

{
  config,
  ...
}:

{
  programs = {
    # --- Nix Index ----------------------------------------------------------
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    # --- Starship Prompt ----------------------------------------------------
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromTOML (builtins.readFile ../configs/apps/starship.toml);
    };

    # --- FZF (Fuzzy Finder) -------------------------------------------------
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
      ];
    };

    # --- Zoxide (Smart Directory Jumper) ------------------------------------
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # --- Direnv (Directory Environment) -------------------------------------
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };

    # --- Eza (ls replacement) -----------------------------------------------
    eza = {
      enable = true;
      enableZshIntegration = false; # Custom aliases defined elsewhere
      git = true;
      icons = "auto";
    };

    # --- Bat (cat replacement) ----------------------------------------------
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        style = "numbers,changes";
      };
    };

    # --- Ripgrep (grep replacement) -----------------------------------------
    ripgrep = {
      enable = true;
      arguments = [
        "--smart-case"
        "--hidden"
        "--glob=!.git/*"
      ];
    };
  };
}
