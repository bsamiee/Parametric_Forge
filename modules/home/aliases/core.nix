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
    ls = "eza -la --header --no-user --time-style=relative";
    tree = "eza --tree";
    du = "dust";
    df = "duf";

    # --- System Operations --------------------------------------------------
    grep = "rg";
    cat = "bat";
    find = "fd";
    ps = "procs";
    top = "btm";                  # Modern system monitor
    cloc = "tokei";               # Modern code counter
    tldru = "tldr --update";      # Update tldr cache
    # man handled by batman export-env in zsh/init.nix - DO NOT alias here

    # --- Search Tools -------------------------------------------------------
    rgg = "rg --json 2>/dev/null | delta";    # Search with delta syntax highlighting
    batg = "batgrep";                         # Bat-powered ripgrep (via bat-extras)

    # --- Trash Management ---------------------------------------------------
    trash = "trash-put";        # Send files to trash
    restore = "trash-restore";  # Restore files from trash
    trashls = "trash-list";     # List trashed files
    trashrm = "trash-rm";       # Remove specific files from trash
    trashempty = "trash-empty"; # Empty entire trash

    # --- Directory Navigation -----------------------------------------------
    "." = "cd ..";          # Up one level
    ".." = "cd ../..";      # Up two levels
    "-" = "cd -";            # Previous directory
  };
}
