# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/core.nix
# ----------------------------------------------------------------------------
# Core shell aliases with modern CLI replacements

_:

{
  # --- Core Unix Command Replacements ---------------------------------------
  ls = "eza -l --no-user"; # List with details
  ll = "eza -la --no-user"; # List all with details
  la = "eza -a"; # List all files
  lt = "eza --tree"; # Tree view
  cat = "bat";
  grep = "rg";
  find = "fd";
  ps = "procs";
  top = "btm";
  df = "duf";
  du = "dust";
  diff = "delta";
  dig = "doggo";
  hex = "hexyl";

  # --- Safety Aliases -------------------------------------------------------
  rm = "trash-put"; # Safe deletion to trash
  cp = "fcp"; # Fast parallel copy when available
  mv = "mv -i"; # Interactive by default
  mkdir = "mkdir -p"; # Always create parent directories

  # --- Trash Management -----------------------------------------------------
  trash = "trash-put";
  trash-list = "trash-list";
  trash-restore = "trash-restore";
  trash-empty = "trash-empty";

  # --- Quick File Filters ---------------------------------------------------
  recent = "fd --changed-within 24h --type f"; # Files from last 24h
  old = "fd --changed-before 30d --type f"; # Files older than 30 days
  large = "fd --size +10M --type f"; # Files larger than 10MB

  # --- Text Processing ------------------------------------------------------
  s = "sd"; # Intuitive find/replace (keeps sed available)
  csv = "xsv"; # CSV processor
  col = "choose"; # Human-friendly column selector
  regex = "grex"; # Generate regex from examples

  # JSON operations
  json = "jq ."; # Pretty print
  jsonc = "jq -c ."; # Compact output
  jsonkeys = "jq -r 'keys[]'"; # List keys
  fx = "fx"; # Interactive JSON viewer
  jl = "jless"; # JSON pager

  # --- System Monitoring ----------------------------------------------------
  pst = "procs --tree"; # Process tree
  psm = "procs --sortd mem"; # Sort by memory
  psc = "procs --sortd cpu"; # Sort by CPU

  # Disk usage
  dus = "dust -d 1"; # Current directory summary
  dua = "dust"; # Full tree view

  # --- File Operations ------------------------------------------------------
  zc = "ouch compress"; # Quick compress (auto-detects format by extension)
  uz = "ouch decompress"; # Quick decompress (universal unzip)
  zls = "ouch list"; # List archive contents (peek inside)

  # Sync operations
  sync = "rsync -avP"; # Archive, verbose, progress
  backup = "rsync -avP --delete"; # Mirror with deletion

  # --- Development Tools ----------------------------------------------------
  j = "just"; # Modern task runner (keep make available)
  bench = "hyperfine"; # Benchmarking tool (don't shadow time)
  watch = "watchexec"; # Better file watcher

  # Interactive file explorers
  br = "broot";
  fm = "yazi"; # Fast terminal file manager

  # --- Text Editors ---------------------------------------------------------
  vi = "nvim";
  vim = "nvim";

  # --- SQLite with Extensions -----------------------------------------------
  sqlite = "sqlite3 -init ~/.sqliterc";

  # --- Security & Utilities -------------------------------------------------
  genpass = "openssl rand -base64 32";
  gensecret = "openssl rand -hex 32";
  sha = "shasum -a 256";
  uuid = "uuidgen | tr '[:upper:]' '[:lower:]'";

  # --- Base64 operations ----------------------------------------------------
  b64 = "base64";
  b64d = "base64 -d";

  # Text transformation
  lower = "tr '[:upper:]' '[:lower:]'";
  upper = "tr '[:lower:]' '[:upper:]'";
  trim = "awk '{$1=$1};1'";
  unique = "sort -u";
  count = "sort | uniq -c | sort -rn";
  cols = "column -t";

  # --- Quick Calculations ---------------------------------------------------
  calc = "bc -l";
  hex2dec = "printf '%d\n'";
  dec2hex = "printf '0x%x\n'";

  # --- Environment & System -------------------------------------------------
  envs = "env | sort";
  reload = "exec $SHELL"; # Reload shell
  cls = "clear"; # Windows muscle memory
  rzsh = "source $HOME/.zshrc"; # Reload ZSH config
  ezsh = "$EDITOR $HOME/.zshrc"; # Edit ZSH config

  # --- Time & Date Operations -----------------------------------------------
  now = "date +'%Y-%m-%d %H:%M:%S'"; # ISO 8601 timestamp
  today = "date +'%Y-%m-%d'"; # ISO date for filenames
  epoch = "date +%s"; # Unix timestamp
  week = "date +%V"; # Week number
  timestamp = "date +'%Y%m%d_%H%M%S'"; # Filename-safe timestamp

  # --- History & Command Recall ---------------------------------------------
  h = "history"; # Show history
  hg = "history | rg"; # Search history with ripgrep
  hist = "history | awk '{print $2}' | sort | uniq -c | sort -rn | head -20"; # Top commands

  # --- YAML Processing ------------------------------------------------------
  y2j = "yq eval -o=json"; # YAML to JSON
  j2y = "yq eval -P"; # JSON to YAML
  yaml = "yq eval"; # Process YAML

  # --- SQL Tools ------------------------------------------------------------
  sqlfmt = "sqlfluff format"; # SQL formatter
  sqllint = "sqlfluff lint"; # SQL linter

  # --- HTTP Development Server ----------------------------------------------
  serve = "python3 -m http.server"; # Instant web server on port 8000

  # --- SSH & Remote Operations ----------------------------------------------
  sshkey = "ssh-keygen -t ed25519 -C"; # Generate modern SSH key
  sshcopy = "pbcopy < ~/.ssh/id_ed25519.pub && echo 'SSH key copied to clipboard'"; # Copy SSH key
  ssht = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"; # SSH without host checking (dev only!)

  # --- URL Encoding/Decoding ------------------------------------------------
  urlencode = "python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))'";
  urldecode = "python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))'";

  # --- Quick Navigation Helpers ---------------------------------------------
  cd = "z"; # Use zoxide for all cd operations
  ".." = "cd ..";
  "..." = "cd ../..";
  "...." = "cd ../../..";
  "....." = "cd ../../../..";

  # --- 1Password Secret Management ------------------------------------------
  op-run = "op run --env-file=\"\$OP_ENV_TEMPLATE\" --";
  op-sync = "op read op://Private/1Password/password >/dev/null && echo '✓ 1Password authenticated' || echo '✗ Run: op signin'";
  dev-secrets = "op run --env-file=\"\$OP_ENV_TEMPLATE\" --"; # Secure command execution with secrets
  npm-secure = "op run --env-file=\"\$OP_ENV_TEMPLATE\" -- npm"; # npm with secure environment

  # --- Code Statistics ------------------------------------------------------
  cloc = "tokei";
  loc = "tokei --compact";

  # --- System Information Tools ---------------------------------------------
  # Mac App Store CLI workflow
  masl = "mas list"; # List installed apps
  mass = "mas search"; # Search store
  masi = "mas install"; # Install by ID
  masu = "mas upgrade"; # Upgrade all apps

  # File type detection with useful flags
  ftype = "file -b"; # File type (brief, no filename)
  fmime = "file -bi"; # MIME type + encoding
}
