# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/core.nix
# ----------------------------------------------------------------------------
# Modern CLI replacements for Unix commands and essential shell tools.

{
  pkgs,
  lib,
  context,
  ...
}:

with pkgs;
[
  # --- Modern CLI Replacements ----------------------------------------------
  # File & Directory Operations
  # eza → Managed by programs.eza in shell-tools.nix
  # fd → Managed by programs.fd in shell-tools.nix
  # broot → Managed by programs.broot in shell-tools.nix
  trash-cli # rm → Safe deletion to trash instead of permanent delete
  fcp # cp → Fast parallel file copy (simple cases)
  rsync # mv/sync → Advanced file synchronization and transfer

  # Text Processing & Search
  # bat → Managed by programs.bat in shell-tools.nix
  # ripgrep → Managed by programs.ripgrep in shell-tools.nix
  sd # sed → Intuitive find/replace without regex complexity
  xan # awk/cut → CSV/TSV data processor (xsv successor)
  choose # cut → Human-friendly column selector
  grex # → Generate regex patterns from examples

  # File Analysis & Diff
  delta # diff → Syntax-aware diff viewer with side-by-side view
  tokei # cloc → Fast code statistics (lines, comments, languages)
  file # file → File type detection by content (enhanced classic)

  # System Monitoring
  procs # ps → Process viewer with tree, search, and color
  # bottom → Managed by programs.bottom in shell-tools.nix
  duf # df → Disk usage with visual bars and colors
  dust # du → Directory size analyzer with tree view

  # Network Tools
  xh # curl/wget → Modern HTTP client with intuitive syntax
  # openssh → Managed by programs.ssh in ssh.nix
  doggo # dig → Modern DNS client with colors and DoH/DoT support
  gping # ping → Ping with real-time graphs
  mtr # traceroute+ping → Combined network diagnostic tool

  # --- Shell Enhancements ---------------------------------------------------
  # zoxide → Managed by programs.zoxide in shell-tools.nix
  # starship → Managed by programs.starship in shell-tools.nix
  # direnv → Managed by programs.direnv in shell-tools.nix
  # fzf → Managed by programs.fzf in shell-tools.nix
  vivid # → LS_COLORS generator for better file visualization
  # mcfly → Managed by programs.mcfly in shell-tools.nix
  # zsh-autosuggestions → Managed by programs.zsh.autosuggestion in zsh.nix
  # zsh-syntax-highlighting → Managed by programs.zsh.syntaxHighlighting in zsh.nix
  # zsh-completions → Managed by programs.zsh.enableCompletion in zsh.nix
  # zsh-history-substring-search → Managed by programs.zsh.historySubstringSearch in zsh.nix

  # --- Archive & Compression ------------------------------------------------
  ouch # tar/zip → Universal archive tool (compress/decompress)
  unzip # Utilities for zip archives
  zip # Create zip archives
  zstd # Zstandard compression
  xz # XZ compression utilities
  lz4 # Extremely fast compression
  brotli # Generic-purpose lossless compression
  p7zip # 7-Zip for Unix - Required by yazi for archive preview/extraction
  unar # Universal archive unpacker with lsar - Better archive preview

  # --- GNU Core Utilities ---------------------------------------------------
  # Newer versions than macOS defaults for consistency
  coreutils # GNU core utilities (ls, cp, mv, etc.)
  findutils # GNU find, xargs, etc.
  gnugrep # GNU grep
  gnused # GNU sed
  gawk # GNU awk
  bash # Bash shell (newer version than macOS default)
  gnutar # GNU version of tar

  # --- Terminal Essentials --------------------------------------------------
  yazi # Blazing fast terminal file manager (async, image preview)
  neovim # vim → Hyperextensible text editor
]
++ lib.optionals context.isDarwin [
  # --- macOS-specific packages ---------------------------------------------
  yabai # Tiling window manager for macOS
  skhd # Simple hotkey daemon for macOS
]
