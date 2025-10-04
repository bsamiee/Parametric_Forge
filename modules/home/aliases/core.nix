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
    # --- General Aliases ----------------------------------------------------
    cl = "clear";
    ex = "exit";
    vim = "nvim";

    # --- Shell Configuration ------------------------------------------------
    envs = "env | sort";                            # List environment variables sorted
    ezsh = "$EDITOR $HOME/.zshrc";                  # Edit ZSH config
    rzsh = "source $HOME/.zshrc";                   # Reload ZSH config
    reload = "exec $SHELL";                         # Reload shell

    # --- File Operations ----------------------------------------------------
    ls = "eza -la --header --no-user --time-style=relative";
    tree = "eza --tree";
    cat = "bat";
    find = "fd";
    fda = "fd --hidden --no-ignore -a";             # Find all files, including hidden and ignored
    mv = "mv -iv";                                  # Prompt on overwrite, show actions
    mkdir  = "mkdir -pv";                           # Always create parent directories
    cp = "rsync -ahP --info=progress2 --";          # Progress + metadata (local copy)
    scp = "rsync -ahzP -e ssh";                     # Secure copy with compression
    sync = "rsync -ahP";                            # Archive with progress
    backup = "rsync -ahP --delete";                 # Mirror with deletion
    rcs = "rclone sync --progress --transfers 4";   # Cloud sync with progress
    hex = "hexyl";                                  # Hex viewer
    wget = "aria2c -c";                             # Modern download with resume

    # --- System Monitoring --------------------------------------------------
    ps = "procs";
    pst = "procs --tree";                           # Process tree
    top = "btm";                                    # Modern system monitor
    du = "dust";
    dfi = "dua i";                                  # Interactive disk usage analyzer
    df = "duf";
    cloc = "tokei";                                 # Modern code counter
    loc = "tokei --compact";                        # Compact code counter
    bench = "hyperfine";                            # Modern benchmarking tool

    # --- Text & Search ------------------------------------------------------
    col = "choose";                                 # Human-friendly column selector
    # man = "batman"                                # Handled by batman export-env in zsh/init.nix - DO NOT alias here
    # grep = "rg";                                  # Causes conflicts with -E and -G
    batg = "batgrep";                               # Bat-powered ripgrep (via bat-extras)
    tldru = "tldr --update";                        # Update tldr cache

    # --- Data Processing ----------------------------------------------------
    jqr = "jq -r";                                  # Raw output (no quotes)
    jqc = "jq -c";                                  # Compact JSON output
    jqs = "jq -S";                                  # Sort object keys
    jqi = "jnv";                                    # Interactive JSON viewer/filter
    j2y = "yq eval -P";                             # JSON to YAML
    y2j = "yq eval -o=json";                        # YAML to JSON
    yaml = "yq eval";                               # Process YAML

    # --- Trash Management ---------------------------------------------------
    trash = "trash-put";                            # Send files to trash
    restore = "trash-restore";                      # Restore files from trash
    trashls = "trash-list";                         # List trashed files
    trashrm = "trash-rm";                           # Remove specific files from trash
    trashempty = "trash-empty";                     # Empty entire trash

    # --- Directory Navigation -----------------------------------------------
    cdr = "cd $(git rev-parse --show-toplevel)";    # Jump to repo root
    ".." = "cd ..";                                 # Up one level
    "..." = "cd ../..";                             # Up two levels
    "...." = "cd ../../..";                         # Up three levels
    "....." = "cd ../../../..";                     # Up four levels
    "-" = "cd -";                                   # Previous directory

    # --- Network Tools ------------------------------------------------------
    curl = "curlie";                                # Modern curl with HTTPie-like interface
    http = "xh";                                    # HTTPie compatibility
    https = "xh --https";                           # HTTPS by default
    serve = "python3 -m http.server 8000";          # Quick static server
    bw = "sudo bandwhich";                          # Bandwidth monitor (needs sudo)
    dig = "doggo";                                  # Modern DNS client
    nslookup = "doggo";                             # DNS lookup replacement
    speedtest = "speedtest --accept-license";       # Official Ookla speed test
    lssh = "lazyssh";                               # Interactive SSH manager
    ports = "sudo lsof -iTCP -sTCP:LISTEN -n -P";   # List open ports (needs sudo)
    flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"; # Flush DNS cache (macOS)

    # --- Time & Date Operations ---------------------------------------------
    timestamp = "date +'%Y%m%d_%H%M%S'";            # Filename-safe timestamp
    epoch = "date +%s";                             # Unix timestamp
    now = "date +'%Y-%m-%d %H:%M:%S'";              # ISO 8601 timestamp
    today = "date +'%Y-%m-%d'";                     # ISO date for filenames
    week = "date +%V";                              # Week number

    # --- 1Password Operations -----------------------------------------------
    ops = "op item list --format=json | jq -r '.[] | \"\\(.id) \\(.title)\"'"; # List items
    opg = "op item get";                            # Get item details
    opr = "op run --";                              #  Run command with secrets injected
    opi = "op inject -i";                           # Inject secrets into template

    # --- Zellij Operations --------------------------------------------------
    zjl = "zellij list-sessions";                   # List all zellij sessions
    zja = "zellij attach";                          # Attach to session "zja <session_name>"
    zjd = "zellij delete-session";                  # Delete a target session "zjd <session_name>"
    zjda = "zellij delete-all-sessions";            # Delete all zellij sessions
    zjk = "zellij kill-session";                    # Kill a target session "zjk <session_name>"
    zjka = "zellij kill-all-sessions";              # Kill all zellij sessions

    # --- MacOS Specific -----------------------------------------------------
    awake = "caffeinate -dims";                     # Prevent sleep (Ctrl+C to stop)
    reveal = "open -R";                             # Reveal file in Finder
    lsapps = "ls /Applications";                    # List installed applications
    o = "open";                                     # Open file/URL with default app
    oo = "open .";                                  # Open current directory in Finder
    qq = "qlmanage -p 2>/dev/null";                 # Preview without opening app
  };
}
