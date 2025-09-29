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
    # --- Core Operations ----------------------------------------------------
    ls = "eza -la --header --no-user --time-style=relative";
    tree = "eza --tree";
    du = "dust";
    df = "duf";
    cat = "bat";
    ps = "procs";
    top = "btm";                              # Modern system monitor
    cloc = "tokei";                           # Modern code counter
    tldru = "tldr --update";                  # Update tldr cache
    # man = "batman"                          # Handled by batman export-env in zsh/init.nix - DO NOT alias here
    # grep = "rg";                            # Causes conflicts with -E and -G
    rgg = "rg --json 2>/dev/null | delta";    # Search with delta syntax highlighting
    batg = "batgrep";                         # Bat-powered ripgrep (via bat-extras)
    find = "fd";

    # --- JSON Processing ----------------------------------------------------
    jqr = "jq -r";              # Raw output (no quotes)
    jqc = "jq -c";              # Compact JSON output
    jqs = "jq -S";              # Sort object keys

    # --- Trash Management ---------------------------------------------------
    trash = "trash-put";        # Send files to trash
    restore = "trash-restore";  # Restore files from trash
    trashls = "trash-list";     # List trashed files
    trashrm = "trash-rm";       # Remove specific files from trash
    trashempty = "trash-empty"; # Empty entire trash

    # --- Directory Navigation -----------------------------------------------
    "." = "cd ..";              # Up one level
    ".." = "cd ../..";          # Up two levels
    "-" = "cd -";               # Previous directory

    # --- Network Tools ------------------------------------------------------
    http = "xh";                # HTTPie compatibility
    https = "xh --https";       # HTTPS by default
    bw = "sudo bandwhich";      # Bandwidth monitor (needs sudo)
    dig = "doggo";              # Modern DNS client
    nslookup = "doggo";         # DNS lookup replacement
    speedtest = "speedtest --accept-license"; # Official Ookla speed test
  };
}
