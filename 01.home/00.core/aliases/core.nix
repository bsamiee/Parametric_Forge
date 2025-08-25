# Title         : core.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/aliases/core.nix
# ----------------------------------------------------------------------------
# Core shell aliases for enhanced functionality

{ ... }:

{
  # --- SQLite with Extensions ----------------------------------------------
  sqlite3 = ''sqlite3 -init ~/.sqliterc'';

  # --- Memory System Shortcuts ---------------------------------------------
  mem = ''~/.claude/hooks/memory.sh''; # Claude memory system alias
  mem-stats = ''~/.claude/hooks/memory.sh stats''; # Claude memory system alias
  mem-errors = ''~/.claude/hooks/memory.sh errors''; # Claude memory system alias
  mem-query = ''~/.claude/hooks/memory.sh query''; # Claude memory system alias
}