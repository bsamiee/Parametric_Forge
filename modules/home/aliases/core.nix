# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/core.nix
# ----------------------------------------------------------------------------
# Core register rows: system, files, monitoring, data, network, dev; desc/category/risk fields are row payload, not comment prose.
[
  # --- [GENERAL]
  {
    alias = "cl";
    expansion = "clear";
    desc = "Clear screen";
    category = "general";
  }
  {
    alias = "vim";
    expansion = "nvim";
    desc = "Neovim as vim";
    category = "general";
  }
  {
    alias = "nv";
    expansion = "nvim";
    desc = "Neovim shorthand";
    category = "general";
  }
  {
    alias = "ff";
    expansion = "fastfetch";
    desc = "System summary";
    category = "general";
  }
  # --- [SHELL]
  {
    alias = "envs";
    expansion = "env | sort";
    desc = "Environment variables sorted";
    category = "shell";
  }
  {
    alias = "ezsh";
    expansion = "$EDITOR \${ZDOTDIR:-$HOME}/.zshrc";
    desc = "Edit zsh config";
    category = "shell";
  }
  {
    alias = "rzsh";
    expansion = "source \${ZDOTDIR:-$HOME}/.zshrc";
    desc = "Reload zsh config";
    category = "shell";
  }
  {
    alias = "reload";
    expansion = "exec $SHELL";
    desc = "Replace shell process";
    category = "shell";
  }
  # --- [FILES]
  {
    alias = "ls";
    expansion = "eza -la --header --no-user --time-style=relative";
    desc = "Long listing via eza";
    category = "files";
  }
  {
    alias = "fda";
    expansion = "fd --hidden --no-ignore -a";
    desc = "Find all files incl. hidden/ignored";
    category = "files";
  }
  {
    alias = "mkdir";
    expansion = "mkdir -pv";
    desc = "Create parents verbosely";
    category = "files";
  }
  {
    alias = "rsmv";
    expansion = "rsync-mv.sh";
    desc = "Atomic move with directory cleanup";
    category = "files";
  }
  {
    alias = "yz";
    expansion = "forge-yazi.sh reveal";
    desc = "Reveal a path in the tab's yazi popup (creates it when absent)";
    category = "files";
  }
  {
    alias = "yzd";
    expansion = "forge-yazi.sh cd";
    desc = "Retarget the tab's yazi popup to a directory";
    category = "files";
  }
  {
    alias = "cpsp";
    expansion = "rsync -ahPSX --";
    desc = "Sparse copy (VMs, disk images)";
    category = "files";
  }
  {
    alias = "backup";
    expansion = "rsync -ahPX --delete";
    desc = "Mirror with deletion";
    category = "files";
    risk = "destructive";
  }
  {
    alias = "rsyncd";
    expansion = "rsync -ahPn";
    desc = "Dry-run transfer preview";
    category = "files";
  }
  {
    alias = "rsyncf";
    expansion = "rsync -ahPX --append-verify";
    desc = "Resume interrupted transfers";
    category = "files";
  }
  {
    alias = "rcs";
    expansion = "rclone sync --progress --transfers 4";
    desc = "Cloud sync with progress";
    category = "files";
    risk = "destructive";
  }
  {
    alias = "hex";
    expansion = "hexyl";
    desc = "Hex viewer";
    category = "files";
  }
  {
    alias = "pack";
    expansion = "ouch compress";
    desc = "Compress files/directories";
    category = "files";
  }
  {
    alias = "unpack";
    expansion = "ouch decompress";
    desc = "Decompress archives";
    category = "files";
  }
  # --- [MONITORING]
  {
    alias = "pst";
    expansion = "procs --tree";
    desc = "Process tree";
    category = "monitoring";
  }
  {
    alias = "psc";
    expansion = "procs --sortd cpu";
    desc = "Processes by CPU";
    category = "monitoring";
  }
  {
    alias = "psm";
    expansion = "procs --sortd mem";
    desc = "Processes by memory";
    category = "monitoring";
  }
  {
    alias = "psw";
    expansion = "procs --watch";
    desc = "Watch processes";
    category = "monitoring";
  }
  {
    alias = "top";
    expansion = "btm";
    desc = "System monitor";
    category = "monitoring";
  }
  {
    alias = "dfi";
    expansion = "dua i";
    desc = "Interactive disk usage";
    category = "monitoring";
  }
  {
    alias = "killi";
    expansion = "pik";
    desc = "Interactive process killer";
    category = "monitoring";
    risk = "destructive";
  }
  {
    alias = "bench";
    expansion = "hyperfine";
    desc = "Command benchmarking";
    category = "monitoring";
  }
  # --- [TEXT_SEARCH]
  {
    alias = "chs";
    expansion = "choose";
    desc = "Column selector";
    category = "text-search";
  }
  {
    alias = "rg";
    expansion = "rg --max-columns=150 --max-columns-preview --trim";
    desc = "Ripgrep with terminal display cosmetics";
    category = "text-search";
  }
  {
    alias = "xh";
    expansion = "xh --style=fruity --print=hbH --pretty=all";
    desc = "HTTP client with terminal display cosmetics";
    category = "network";
  }
  {
    alias = "sqlite3";
    expansion = "sqlite3 -column -header -nullvalue NULL";
    desc = "SQLite shell with terminal display defaults";
    category = "data";
  }
  {
    alias = "batg";
    expansion = "batgrep";
    desc = "Bat-powered ripgrep";
    category = "text-search";
  }
  {
    alias = "tldru";
    expansion = "tldr --update";
    desc = "Update tldr cache";
    category = "text-search";
  }
  {
    alias = "rgx";
    expansion = "grex -xc";
    desc = "Regex from test cases";
    category = "text-search";
  }
  {
    alias = "rgxf";
    expansion = "grex -xc -f";
    desc = "Regex from file input";
    category = "text-search";
  }
  {
    alias = "sr";
    expansion = "serpl";
    desc = "TUI search and replace";
    category = "text-search";
  }
  {
    alias = "mdv";
    expansion = "rich --markdown";
    desc = "Markdown viewer";
    category = "text-search";
  }
  # --- [SCREENSHOT]
  {
    alias = "carbonc";
    expansion = "carbon-now.sh --to-clipboard";
    desc = "Code screenshot to clipboard";
    category = "screenshot";
  }
  {
    alias = "carboni";
    expansion = "carbon-now.sh --interactive";
    desc = "Code screenshot interactive";
    category = "screenshot";
  }
  # --- [DATA]
  {
    alias = "jqr";
    expansion = "jq -r";
    desc = "Raw jq output";
    category = "data";
  }
  {
    alias = "jqc";
    expansion = "jq -c";
    desc = "Compact JSON output";
    category = "data";
  }
  {
    alias = "jqs";
    expansion = "jq -S";
    desc = "Sort object keys";
    category = "data";
  }
  {
    alias = "jqi";
    expansion = "jnv";
    desc = "Interactive JSON explorer";
    category = "data";
  }
  {
    alias = "hq";
    expansion = "harlequin";
    desc = "Terminal SQL IDE";
    category = "data";
  }
  {
    alias = "fqd";
    expansion = "fq d";
    desc = "Decode binary file structure";
    category = "data";
  }
  {
    alias = "j2y";
    expansion = "yq eval -P";
    desc = "JSON to YAML";
    category = "data";
  }
  {
    alias = "y2j";
    expansion = "yq eval -o=json";
    desc = "YAML to JSON";
    category = "data";
  }
  {
    alias = "yaml";
    expansion = "yq eval";
    desc = "Process YAML";
    category = "data";
  }
  {
    alias = "c2j";
    expansion = "mlr --c2j cat";
    desc = "CSV to JSON";
    category = "data";
  }
  {
    alias = "j2c";
    expansion = "mlr --j2c cat";
    desc = "JSON to CSV";
    category = "data";
  }
  # --- [TRASH]
  {
    alias = "trestore";
    expansion = "trash-restore";
    desc = "Restore from trash";
    category = "trash";
  }
  {
    alias = "tls";
    expansion = "trash-list";
    desc = "List trashed files";
    category = "trash";
  }
  {
    alias = "trm";
    expansion = "trash-rm";
    desc = "Remove specific trashed files";
    category = "trash";
    risk = "destructive";
  }
  {
    alias = "tempty";
    expansion = "trash-empty";
    desc = "Empty entire trash";
    category = "trash";
    risk = "destructive";
  }
  # --- [NAVIGATION]
  {
    alias = "cdr";
    expansion = "cd $(git rev-parse --show-toplevel)";
    desc = "Jump to repo root";
    category = "navigation";
  }
  {
    alias = "..";
    expansion = "cd ..";
    desc = "Up one level";
    category = "navigation";
  }
  {
    alias = "...";
    expansion = "cd ../..";
    desc = "Up two levels";
    category = "navigation";
  }
  {
    alias = "....";
    expansion = "cd ../../..";
    desc = "Up three levels";
    category = "navigation";
  }
  {
    alias = ".....";
    expansion = "cd ../../../..";
    desc = "Up four levels";
    category = "navigation";
  }
  {
    alias = "-";
    expansion = "cd -";
    desc = "Previous directory";
    category = "navigation";
  }
  # --- [NETWORK]
  {
    alias = "http";
    expansion = "xh";
    desc = "HTTPie-compatible client";
    category = "network";
  }
  {
    alias = "https";
    expansion = "xh --https";
    desc = "HTTPS by default";
    category = "network";
  }
  {
    alias = "POST";
    expansion = "xh POST";
    desc = "RESTful POST";
    category = "network";
  }
  {
    alias = "PUT";
    expansion = "xh PUT";
    desc = "RESTful PUT";
    category = "network";
  }
  {
    alias = "tripu";
    expansion = "trip --udp --target-port 33434";
    desc = "UDP tracing for ECMP paths";
    category = "network";
  }
  {
    alias = "ohaj";
    expansion = "oha --no-tui --output-format json";
    desc = "HTTP load run with JSON report";
    category = "network";
  }
  {
    alias = "serve";
    expansion = "python3 -m http.server 8000";
    desc = "Quick static server";
    category = "network";
  }
  {
    alias = "bw";
    expansion = "sudo bandwhich";
    desc = "Bandwidth monitor";
    category = "network";
    risk = "sudo";
  }
  {
    alias = "speedtestl";
    expansion = "speedtest --accept-license";
    desc = "Ookla speed test, license pre-accepted";
    category = "network";
  }
  {
    alias = "lssh";
    expansion = "sshs";
    desc = "Interactive SSH picker";
    category = "network";
  }
  {
    alias = "whs";
    expansion = "forge-webhook -verbose";
    desc = "Foreground webhook listener with verbose logs (boot the launchd agent out first)";
    category = "network";
  }
  {
    alias = "ports";
    expansion = "sudo lsof -iTCP -sTCP:LISTEN -n -P";
    desc = "List listening TCP ports";
    category = "network";
    risk = "sudo";
  }
  {
    alias = "flushdns";
    expansion = "sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder";
    desc = "Flush macOS DNS cache";
    category = "network";
    risk = "sudo";
  }
  # --- [TIME]
  {
    alias = "timestamp";
    expansion = "date +'%Y%m%d_%H%M%S'";
    desc = "Filename-safe timestamp";
    category = "time";
  }
  {
    alias = "epoch";
    expansion = "date +%s";
    desc = "Unix timestamp";
    category = "time";
  }
  {
    alias = "now";
    expansion = "date +'%Y-%m-%d %H:%M:%S'";
    desc = "ISO 8601 timestamp";
    category = "time";
  }
  {
    alias = "today";
    expansion = "date +'%Y-%m-%d'";
    desc = "ISO date";
    category = "time";
  }
  {
    alias = "week";
    expansion = "date +%V";
    desc = "Week number";
    category = "time";
  }
  # --- [1PASSWORD]
  {
    alias = "opls";
    expansion = "op item list --format=json | jq -r '.[] | \"\\(.id) \\(.title)\"'";
    desc = "List 1Password items";
    category = "1password";
  }
  {
    alias = "opg";
    expansion = "op item get";
    desc = "Get item details";
    category = "1password";
  }
  {
    alias = "opr";
    expansion = "op run --";
    desc = "Run with secrets injected";
    category = "1password";
  }
  {
    alias = "opi";
    expansion = "op inject -i";
    desc = "Inject secrets into template";
    category = "1password";
  }
  # --- [ZELLIJ]
  {
    alias = "zjl";
    expansion = "zellij list-sessions";
    desc = "List sessions";
    category = "zellij";
  }
  {
    alias = "zja";
    expansion = "zellij attach";
    desc = "Attach to session";
    category = "zellij";
  }
  {
    alias = "zjd";
    expansion = "zellij delete-session";
    desc = "Delete a session";
    category = "zellij";
    risk = "session-destructive";
  }
  {
    alias = "zjda";
    expansion = "zellij delete-all-sessions";
    desc = "Delete all sessions";
    category = "zellij";
    risk = "session-destructive";
  }
  {
    alias = "zjk";
    expansion = "zellij kill-session";
    desc = "Kill a session";
    category = "zellij";
    risk = "session-destructive";
  }
  {
    alias = "zjka";
    expansion = "zellij kill-all-sessions";
    desc = "Kill all sessions";
    category = "zellij";
    risk = "session-destructive";
  }
  # --- [ACTIONS]
  {
    alias = "actl";
    expansion = "act -l";
    desc = "List workflows/jobs";
    category = "actions";
  }
  {
    alias = "alint";
    expansion = "actionlint";
    desc = "Lint workflow files";
    category = "actions";
  }
  # --- [DEV]
  {
    alias = "tyc";
    expansion = "ty check";
    desc = "Type-check shorthand";
    category = "dev";
  }
  {
    alias = "rfix";
    expansion = "ruff check --fix";
    desc = "Ruff autofix";
    category = "dev";
  }
  {
    alias = "rformat";
    expansion = "ruff format";
    desc = "Ruff format";
    category = "dev";
  }
  {
    alias = "rhproject";
    expansion = "dotnet new rhino -sample";
    desc = "Rhino plugin template";
    category = "dev";
  }
  {
    alias = "ghproject";
    expansion = "dotnet new grasshopper -sample";
    desc = "Grasshopper template";
    category = "dev";
  }
  {
    alias = "watch";
    expansion = "watchexec -c";
    desc = "Clear terminal on file change";
    category = "dev";
  }
  {
    alias = "watchr";
    expansion = "watchexec -r";
    desc = "Restart process on file change";
    category = "dev";
  }
  {
    alias = "pc";
    expansion = "process-compose";
    desc = "Project-local process mesh";
    category = "dev";
  }
  {
    alias = "pdev";
    expansion = "pnpm dev";
    desc = "Vite dev server";
    category = "dev";
  }
  {
    alias = "pbuild";
    expansion = "pnpm build";
    desc = "Production build";
    category = "dev";
  }
  {
    alias = "ptest";
    expansion = "pnpm test";
    desc = "Run Vitest tests";
    category = "dev";
  }
  {
    alias = "dnr";
    expansion = "dotnet run --";
    desc = "dotnet run with args";
    category = "dev";
  }
  {
    alias = "dnw";
    expansion = "dotnet watch run --";
    desc = "dotnet hot reload";
    category = "dev";
  }
  {
    alias = "dnb";
    expansion = "dotnet build -c Release";
    desc = "dotnet release build";
    category = "dev";
  }
  {
    alias = "dnt";
    expansion = "dotnet test --logger 'console;verbosity=minimal'";
    desc = "dotnet clean test output";
    category = "dev";
  }
  {
    alias = "yakb";
    expansion = "yak build";
    desc = "Package Rhino plugins";
    category = "dev";
  }
  {
    alias = "rhcode";
    expansion = "rhinocode";
    desc = "Rhino script compiler";
    category = "dev";
  }
  # --- [MACOS]
  {
    alias = "awake";
    expansion = "caffeinate -dims";
    desc = "Prevent sleep";
    category = "macos";
  }
  {
    alias = "reveal";
    expansion = "open -R";
    desc = "Reveal in Finder";
    category = "macos";
  }
  {
    alias = "lsapps";
    expansion = "ls /Applications";
    desc = "List installed applications";
    category = "macos";
  }
  {
    alias = "o";
    expansion = "open";
    desc = "Open with default app";
    category = "macos";
  }
  {
    alias = "oo";
    expansion = "open .";
    desc = "Open cwd in Finder";
    category = "macos";
  }
  {
    alias = "qq";
    expansion = "qlmanage -p 2>/dev/null";
    desc = "Quick Look preview";
    category = "macos";
  }
]
