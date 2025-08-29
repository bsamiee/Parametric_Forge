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
  # eza/fd/broot → Managed by programs in shell-tools.nix
  trash-cli # rm → Safe deletion
  fcp # cp → Fast parallel copy
  rsync # sync → File synchronization

  # bat/ripgrep → Managed by programs in shell-tools.nix
  sd # sed → Find/replace
  xan # awk → CSV/TSV processor
  choose # cut → Column selector
  grex # → Regex generator

  delta # diff → Syntax-aware viewer
  tokei # cloc → Code statistics
  file # → Enhanced file detection

  # System Monitoring
  procs # ps → Process viewer
  # bottom → Managed by programs in shell-tools.nix
  duf # df → Disk usage
  dust # du → Directory size analyzer

  xh # curl → HTTP client
  # openssh → Managed by programs in ssh.nix
  doggo # dig → DNS client
  gping # ping → Real-time graphs
  mtr # traceroute+ping

  # --- Shell Enhancements ---------------------------------------------------
  # zoxide/starship/direnv/fzf/mcfly → Managed by programs in shell-tools.nix
  # zsh plugins → Managed by programs in zsh.nix
  vivid # → LS_COLORS generator

  # --- Archive & Compression ------------------------------------------------
  ouch # tar/zip → Universal archive tool
  unzip
  zip
  zstd
  xz
  lz4
  brotli
  p7zip # Required by yazi
  unar # Archive preview

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
