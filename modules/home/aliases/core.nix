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
    ff = "fastfetch";

    # --- Shell Configuration ------------------------------------------------
    envs = "env | sort";                                                          # List environment variables sorted
    ezsh = "$EDITOR $HOME/.zshrc";                                                # Edit ZSH config
    rzsh = "source $HOME/.zshrc";                                                 # Reload ZSH config
    reload = "exec $SHELL";                                                       # Reload shell                                                                 # Keep npm calls consistent                                                                # Convenience typo/alias

    # --- File Operations ----------------------------------------------------
    ls = "eza -la --header --no-user --time-style=relative";
    tree = "eza --tree";
    cat = "bat";
    find = "fd";
    fda = "fd --hidden --no-ignore -a";                                           # Find all files, including hidden and ignored
    mv = "rsync-mv";                                                              # Atomic move with directory cleanup
    mkdir  = "mkdir -pv";                                                         # Always create parent directories
    cp = "rsync -ahPX --info=progress2 --";                                       # Full preservation, no sparse
    cpsp = "rsync -ahPSX --";                                                     # Sparse copy (VMs, disk images)
    scp = "rsync -ahzPX -e ssh";                                                  # Remote copy with compression
    sync = "rsync -ahPX --inplace";                                               # In-place update (large files)
    backup = "rsync -ahPX --delete";                                              # Mirror with deletion
    rsyncd = "rsync -ahPn";                                                       # Dry-run with progress (safety check)
    rsyncf = "rsync -ahPX --append-verify";                                       # Resume interrupted transfers
    rcs = "rclone sync --progress --transfers 4";                                 # Cloud sync with progress
    hex = "hexyl";                                                                # Hex viewer
    wget = "aria2c -c";                                                           # Modern download with resume
    pack = "ouch compress";                                                       # Compress files/directories
    unpack = "ouch decompress";                                                   # Decompress archives
    mountar = "archivemount";                                                     # Mount archives as filesystem

    # --- System Monitoring --------------------------------------------------
    ps = "procs";
    pst = "procs --tree";                                                         # Process tree
    psc = "procs --sortd 5";                                                      # Sort processes by CPU usage
    psm = "procs --sortd 6";                                                      # Sort processes by memory usage
    psw = "procs --watch";                                                        # Watch processes (2s refresh)
    top = "btm";                                                                  # Modern system monitor
    df = "duf";
    du = "dust";
    dfi = "dua i";                                                                # Interactive disk usage analyzer
    killi = "pik";                                                                # Interactive process killer
    cloc = "tokei";                                                               # Modern code counter
    loc = "tokei --compact";                                                      #  Compact code counter
    locj = "tokei --output json";                                                 # Code stats as JSON for scripting
    bench = "hyperfine";                                                          # Modern benchmarking tool

    # --- Text & Search ------------------------------------------------------
    col = "choose";                                                               # Human-friendly column selector
    # man = "batman"                                                              # Handled by batman export-env in zsh/init.nix - DO NOT alias here
    # grep = "rg";                                                                # Causes conflicts with -E and -G
    batg = "batgrep";                                                             # Bat-powered ripgrep (via bat-extras)
    tldru = "tldr --update";                                                      # Update tldr cache
    rgx = "grex -xc";                                                             # Generate readable regex from test cases
    rgxf = "grex -xc -f";                                                         # File input with readable output
    sdi = "sd -i";                                                                # In-place find/replace (sed -i pattern)
    sr = "serpl";                                                                 # TUI search and replace

    # --- Formatting Tools ---------------------------------------------------
    mdv = "rich --markdown";                                                      # Markdown viewer (like hex for hexyl)

    # --- Code Screenshot ----------------------------------------------------
    carbonc = "carbon-now --to-clipboard";                                       # Carbon screenshot to clipboard
    carboni = "carbon-now --interactive";                                        # Carbon interactive mode

    # --- Data Processing ----------------------------------------------------
    jqr = "jq -r";                                                                # Raw output (no quotes)
    jqc = "jq -c";                                                                # Compact JSON output
    jqs = "jq -S";                                                                # Sort object keys
    jqi = "jnv";                                                                  # Interactive JSON viewer/filter
    j2y = "yq eval -P";                                                           # JSON to YAML
    y2j = "yq eval -o=json";                                                      # YAML to JSON
    yaml = "yq eval";                                                             # Process YAML

    # --- Data Conversion ----------------------------------------------------
    c2j = "mlr --c2j cat";                                                        # CSV to JSON
    j2c = "mlr --j2c cat";                                                        # JSON to CSV

    # --- Trash Management ---------------------------------------------------
    tput = "trash-put";                                                           # Send files to trash
    trestore = "trash-restore";                                                   # Restore files from trash
    tls = "trash-list";                                                           # List trashed files
    trm = "trash-rm";                                                             # Remove specific files from trash
    tempty = "trash-empty";                                                       # Empty entire trash

    # --- Directory Navigation -----------------------------------------------
    cdr = "cd $(git rev-parse --show-toplevel)";                                  # Jump to repo root
    ".." = "cd ..";                                                               # Up one level
    "..." = "cd ../..";                                                           # Up two levels
    "...." = "cd ../../..";                                                       # Up three levels
    "....." = "cd ../../../..";                                                   # Up four levels
    "-" = "cd -";                                                                 # Previous directory

    # --- Network Tools ------------------------------------------------------
    curl = "curlie";                                                              # Modern curl with HTTPie-like interface
    http = "xh";                                                                  # HTTPie compatibility
    https = "xh --https";                                                         # HTTPS by default
    POST = "xh POST";                                                             # RESTful convention
    PUT = "xh PUT";                                                               # RESTful convention
    ping = "gping";                                                               # Visual ping with graph
    trace = "trippy";                                                             # Modern traceroute replacement
    traceu = "trippy --udp --target-port 33434";                                  # UDP tracing for ECMP paths
    serve = "python3 -m http.server 8000";                                        # Quick static server
    bw = "sudo bandwhich";                                                        # Bandwidth monitor (needs sudo)
    dig = "doggo";                                                                # Modern DNS client
    nslookup = "doggo";                                                           # DNS lookup replacement
    speedtest = "speedtest --accept-license";                                     # Official Ookla speed test
    lssh = "sshs";                                                                 # Interactive SSH picker
    whs = "webhook -hooks $WEBHOOK_HOOKS_DIR/hooks.json -verbose";                # Start webhook server
    ports = "sudo lsof -iTCP -sTCP:LISTEN -n -P";                                 # List open ports (needs sudo)
    flushdns = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"; # Flush DNS cache (macOS)

    # --- Time & Date Operations ---------------------------------------------
    timestamp = "date +'%Y%m%d_%H%M%S'";                                          # Filename-safe timestamp
    epoch = "date +%s";                                                           # Unix timestamp
    now = "date +'%Y-%m-%d %H:%M:%S'";                                            # ISO 8601 timestamp
    today = "date +'%Y-%m-%d'";                                                   # ISO date for filenames
    week = "date +%V";                                                            # Week number

    # --- 1Password Operations -----------------------------------------------
    opls = "op item list --format=json | jq -r '.[] | \"\\(.id) \\(.title)\"'";   # List items
    opg = "op item get";                                                          # Get item details
    opr = "op run --";                                                            # Run command with secrets injected
    opi = "op inject -i";                                                         # Inject secrets into template

    # --- Zellij Operations --------------------------------------------------
    zjl = "zellij list-sessions";                                                 # List all zellij sessions
    zja = "zellij attach";                                                        # Attach to session "zja <session_name>"
    zjd = "zellij delete-session";                                                # Delete a target session "zjd <session_name>"
    zjda = "zellij delete-all-sessions";                                          # Delete all zellij sessions
    zjk = "zellij kill-session";                                                  # Kill a target session "zjk <session_name>"
    zjka = "zellij kill-all-sessions";                                            # Kill all zellij sessions

    # --- Dev Tools ----------------------------------------------------------
    pyright = "basedpyright";
    rfix = "ruff check --fix";
    rformat = "ruff format";
    rhproject = "dotnet new rhino --version 8 -sample";                           # Initialize new Rhino plugin project template
    ghproject = "dotnet new grasshopper --version 8 -sample";                     # Initialize new Grasshopper plugin project template
    watch = "watchexec -c";                                                       # Clear terminal on file change
    watchr = "watchexec -r";                                                      # Restart process on file change

    # --- TypeScript/React Development --------------------------------------
    pdev = "pnpm dev";                                                            # Start Vite dev server
    pbuild = "pnpm build";                                                        # Production build with type checking
    ptest = "pnpm test";                                                          # Run Vitest tests
    # Biome
    bc = "biome check --error-on-warnings";                                       # Check format + lint + imports
    bcw = "biome check --write";                                                  # Apply safe fixes + format
    bcu = "biome check --write --unsafe";                                         # Apply all fixes including unsafe
    brage = "biome rage --formatter --linter --verbose";                          # Debug configuration
    bcwatch = "watchexec -c -e js,jsx,ts,tsx,json,css -- biome check";            # Watch and check on changes
    bfwatch = "watchexec -c -e js,jsx,ts,tsx,json,css -- biome format --write";   # Watch and format on changes

    # --- .NET Development ---------------------------------------------------
    dnr = "dotnet run --";                                                        # Run with args passthrough
    dnw = "dotnet watch run --";                                                  # Hot reload development
    dnb = "dotnet build -c Release";                                              # Production builds for plugins
    dnt = "dotnet test --logger 'console;verbosity=minimal'";                     # Clean test output

    # --- Rhino/Grasshopper Tools -------------------------------------------
    yakb = "yak build";                                                           # Package Rhino plugins
    rhcode = "rhinocode";                                                         # Shorter script compiler alias

    # --- MacOS Specific -----------------------------------------------------
    awake = "caffeinate -dims";                                                   # Prevent sleep (Ctrl+C to stop)
    reveal = "open -R";                                                           # Reveal file in Finder
    lsapps = "ls /Applications";                                                  # List installed applications
    o = "open";                                                                   # Open file/URL with default app
    oo = "open .";                                                                # Open current directory in Finder
    qq = "qlmanage -p 2>/dev/null";                                               # Preview without opening app
  };
}
