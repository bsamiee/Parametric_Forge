# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/core.nix
# ----------------------------------------------------------------------------
# Core system aliases for common operations

{ lib, pkgs, ... }:

{
  programs.zsh.shellAliases = {
    # --- File Operations -----------------------------------------------------
    ls = "eza";                         # Basic listing (uses defaults from eza.nix)
    ll = "eza -l --header";             # Long format with details + header
    la = "eza -a";                      # Show hidden files
    lla = "eza -la --header";           # All files in long format
    tree = "eza --tree";                # Tree view

    # --- System Operations --------------------------------------------------
    grep = "rg";
    cat = "bat";
    find = "fd";

    # --- Trash Management ---------------------------------------------------
    trash = "trash-put";        # Send files to trash
    restore = "trash-restore";  # Restore files from trash
    trashls = "trash-list";     # List trashed files
    trashrm = "trash-rm";       # Remove specific files from trash
    trashempty = "trash-empty"; # Empty entire trash

    # --- Directory Navigation -----------------------------------------------
    # ".." = "cd ..";
    # "..." = "cd ../..";
    # "...." = "cd ../../..";

    # --- System Info --------------------------------------------------------
    # df = "df -h";
    # du = "du -sh";
    # top = "btm";
  };
}
