# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/core.nix
# ----------------------------------------------------------------------------
# Modern CLI replacements for Unix commands and essential shell tools.

{ pkgs, ... }:

with pkgs;
[
  # --- File & Directory Operations ------------------------------------------
  eza # ls → Modern file listing with git integration, icons, tree view
  fd # find → Fast file finder respecting .gitignore
  broot # tree → Interactive file tree explorer
  trash-cli # rm → Safe deletion to trash instead of permanent delete
  fcp # cp → Fast parallel file copy (simple cases)
  uutils-coreutils-noprefix # Full POSIX cp when fcp lacks features (-r, -p, -a, --reflink CoW)
  rsync # mv/sync → Advanced file synchronization and transfer

  # --- Text Processing & Search ---------------------------------------------
  bat # cat → Syntax highlighting viewer with line numbers
  ripgrep # grep → Ultra-fast text search (rg command)
  sd # sed → Intuitive find/replace without regex complexity
  xan # awk/cut → CSV/TSV data processor (xsv successor)
  choose # cut → Human-friendly column selector
  grex # → Generate regex patterns from examples

  # --- File Analysis & Diff -------------------------------------------------
  delta # diff → Syntax-aware diff viewer with side-by-side view
  hexyl # hexdump/xxd → Colorful hex viewer
  tokei # cloc → Fast code statistics (lines, comments, languages)
  file # file → File type detection by content (enhanced classic)

  # --- System Monitoring ----------------------------------------------------
  procs # ps → Process viewer with tree, search, and color
  bottom # top/htop → Resource monitor with graphs (btm command)
  duf # df → Disk usage with visual bars and colors
  dust # du → Directory size analyzer with tree view

  # --- Network Tools --------------------------------------------------------
  xh # curl/wget → Modern HTTP client with intuitive syntax
  openssh # ssh → SSH client and utilities (enhanced classic)
  doggo # dig → Modern DNS client with colors and DoH/DoT support
  gping # ping → Ping with real-time graphs
  mtr # traceroute+ping → Combined network diagnostic tool

  # --- Shell Enhancements ---------------------------------------------------
  zoxide # cd → Smart directory jumper with frecency (z command)
  starship # PS1 → Fast, customizable cross-shell prompt
  direnv # source → Auto-load environment variables per directory
  fzf # → Fuzzy finder for files, history, processes
  vivid # → LS_COLORS generator for better file visualization
  mcfly # ctrl+r → Smart shell history with neural network ranking

  # --- Archive & Compression ------------------------------------------------
  ouch # tar/zip → Universal archive tool (compress/decompress)
  unzip # Utilities for zip archives
  zip # Create zip archives
  zstd # Zstandard compression
  xz # XZ compression utilities
  lz4 # Extremely fast compression
  brotli # Generic-purpose lossless compression

  # --- SQLite Extensions ----------------------------------------------------
  sqlite # Base SQLite 3.50.2 (newer than macOS default 3.43.2)
  sqlite-vec # Vector search SQLite extension (semantic pattern matching)
  # sqlean - NOT AVAILABLE in nixpkgs, manually installed to ~/.local/lib/sqlean/
  sqlite-interactive # Interactive SQLite CLI with enhanced features
  sqlite-utils # Python CLI tool for SQLite database manipulation
  libspatialite # OGC-compliant spatial SQL engine (GIS operations, coordinate transformations)

  # --- Core GNU Utilities (newer versions than macOS defaults) --------------
  coreutils # GNU core utilities (ls, cp, mv, etc.)
  findutils # GNU find, xargs, etc.
  gnugrep # GNU grep
  gnused # GNU sed
  gawk # GNU awk
  bash # Bash shell (newer version than macOS default)
  gnutar # GNU version of tar
  diffutils # GNU diff utilities

  # --- Terminal File Managers -----------------------------------------------
  yazi # Blazing fast terminal file manager (async, image preview)
  lf # Lightweight terminal file manager (fast, minimal)
  ranger # Feature-rich terminal file manager (Python-based)
  nnn # Extremely fast terminal file manager (n³)

  # --- Zsh Enhancements -----------------------------------------------------
  zsh-autosuggestions # Fish-like autosuggestions for command completion
  zsh-syntax-highlighting # Fish-like syntax highlighting as you type
  zsh-completions # Additional completion definitions for zsh
  zsh-history-substring-search # Fish-like history search with arrow keys
]
