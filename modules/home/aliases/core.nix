# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/core.nix
# ----------------------------------------------------------------------------
# Core register rows: system, files, monitoring, data, network, dev; desc/category/risk fields are row payload, not comment prose.
{
  "1password" = [
    ["opls" "op item list" "List 1Password items"]
    ["opg" "op item get" "Get item details"]
    ["opr" "op run --" "Run with secrets injected"]
    ["opi" "op inject -i" "Inject secrets into template"]
  ];
  actions = [
    ["actl" "act -l" "List workflows/jobs"]
  ];
  data = [
    ["sqlite3" "sqlite3 -column -header -nullvalue NULL" "SQLite shell with terminal display defaults"]
    ["jqi" "jnv" "Interactive JSON explorer"]
    ["hq" "harlequin" "Terminal SQL IDE"]
    ["fqd" "fq d" "Decode binary file structure"]
    ["c2j" "mlr --c2j cat" "CSV to JSON"]
    ["j2c" "mlr --j2c cat" "JSON to CSV"]
  ];
  dev = [
    ["watch" "watchexec -c" "Clear terminal on file change"]
    ["watchr" "watchexec -r" "Restart process on file change"]
    ["pc" "process-compose" "Project-local process mesh"]
    ["pdev" "pnpm dev" "Vite dev server"]
    ["pbuild" "pnpm build" "Production build"]
    ["ptest" "pnpm test" "Run Vitest tests"]
    ["dnr" "dotnet run --" "dotnet run with args"]
    ["dnw" "dotnet watch run --" "dotnet hot reload"]
    ["dnb" "dotnet build -c Release" "dotnet release build"]
    ["dnt" "dotnet test --logger 'console;verbosity=minimal'" "dotnet clean test output"]
  ];
  files = [
    ["ls" "eza -la --header --no-user --time-style=relative" "Long listing via eza"]
    ["mkdir" "mkdir -pv" "Create parents verbosely"]
    ["rcmv" "rclone move --delete-empty-src-dirs" "Move with emptied source directories removed"]
    ["yz" "forge-yazi.sh reveal" "Reveal a path in the tab's yazi popup (creates it when absent)"]
    ["yzd" "forge-yazi.sh cd" "Retarget the tab's yazi popup to a directory"]
    ["cpsp" "rsync -ahPSX --" "Sparse copy (VMs, disk images)"]
    ["backup" "rsync -ahPX --delete" "Mirror with deletion" "destructive"]
    ["rsyncd" "rsync -ahPn" "Dry-run transfer preview"]
    ["rsyncf" "rsync -ahPX --append-verify" "Resume interrupted transfers"]
    ["rcs" "rclone sync --progress --transfers 4" "Cloud sync with progress" "destructive"]
    ["hex" "hexyl" "Hex viewer"]
    ["pack" "ouch compress" "Compress files/directories"]
    ["unpack" "ouch decompress" "Decompress archives"]
  ];
  general = [
    ["cl" "clear" "Clear screen"]
    ["vim" "nvim" "Neovim as vim"]
    ["nv" "nvim" "Neovim shorthand"]
    ["ff" "fastfetch" "System summary"]
  ];
  monitoring = [
    ["pst" "procs --tree" "Process tree"]
    ["psc" "procs --sortd cpu" "Processes by CPU"]
    ["psmem" "procs --sortd mem" "Processes by memory"]
    ["psw" "procs --watch" "Watch processes"]
    ["top" "btm" "System monitor"]
    ["dfi" "dua i" "Interactive disk usage"]
    ["killi" "pik" "Interactive process killer" "destructive"]
  ];
  navigation = [
    ["cdr" "cd $(git rev-parse --show-toplevel)" "Jump to repo root"]
    [".." "cd .." "Up one level"]
    ["..." "cd ../.." "Up two levels"]
    ["...." "cd ../../.." "Up three levels"]
    ["....." "cd ../../../.." "Up four levels"]
    ["-" "cd -" "Previous directory"]
  ];
  network = [
    ["xh" "xh --style=fruity --print=hbH --pretty=all" "HTTP client with terminal display cosmetics"]
    ["http" "xh" "HTTPie-compatible client"]
    ["https" "xh --https" "HTTPS by default"]
    ["POST" "xh POST" "RESTful POST"]
    ["PUT" "xh PUT" "RESTful PUT"]
    ["tripu" "trip --udp --target-port 33434" "UDP tracing for ECMP paths"]
    ["ohaj" "oha --no-tui --output-format json" "HTTP load run with JSON report"]
    ["serve" "rclone serve http --addr :8000 ." "Static server over the working directory"]
    ["bw" "sudo bandwhich" "Bandwidth monitor" "sudo"]
    ["speedtestl" "speedtest --accept-license" "Ookla speed test, license pre-accepted"]
    ["lssh" "sshs" "Interactive SSH picker"]
    ["ports" "sudo lsof -iTCP -sTCP:LISTEN -n -P" "List listening TCP ports" "sudo"]
  ];
  shell = [
    ["envs" "env | sort" "Environment variables sorted"]
    ["ezsh" "$EDITOR \${ZDOTDIR:-$HOME}/.zshrc" "Edit zsh config"]
    ["rzsh" "source \${ZDOTDIR:-$HOME}/.zshrc" "Reload zsh config"]
    ["reload" "exec $SHELL" "Replace shell process"]
  ];
  text-search = [
    ["chs" "choose" "Column selector"]
    ["batg" "batgrep" "Bat-powered ripgrep"]
    ["tldru" "tldr --update" "Update tldr cache"]
    ["rgx" "grex -xc" "Regex from test cases"]
    ["rgxf" "grex -xc -f" "Regex from file input"]
    ["sr" "serpl" "TUI search and replace"]
    ["mdv" "rich --markdown" "Markdown viewer"]
  ];
  time = [
    ["timestamp" "date +'%Y%m%d_%H%M%S'" "Filename-safe timestamp"]
    ["epoch" "date +%s" "Unix timestamp"]
    ["now" "date +'%Y-%m-%d %H:%M:%S'" "ISO 8601 timestamp"]
    ["today" "date +'%Y-%m-%d'" "ISO date"]
    ["week" "date +%V" "Week number"]
  ];
  trash = [
    ["trestore" "trash-restore" "Restore from trash"]
    ["tls" "trash-list" "List trashed files"]
    ["trm" "trash-rm" "Remove specific trashed files" "destructive"]
    ["tempty" "trash-empty" "Empty entire trash" "destructive"]
  ];
  zellij = [
    ["zjl" "zellij list-sessions" "List sessions"]
    ["zja" "zellij attach" "Attach to session"]
  ];
}
