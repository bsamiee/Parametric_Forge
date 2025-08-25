# Title         : lib/exclusion-filters.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /lib/exclusion-filters.nix
# ----------------------------------------------------------------------------
# Filter functions for exclusion patterns.

_:

{
  # --- Filter Logics --------------------------------------------------------
  byType = type: patterns: builtins.filter (e: builtins.elem type e.types) patterns;
  byLocation = loc: patterns: builtins.filter (e: e ? location && e.location == loc) patterns;

  # --- Type Checking --------------------------------------------------------
  hasType = type: pattern: builtins.elem type pattern.types;
  byAnyType = types: patterns: builtins.filter (e: builtins.any (t: builtins.elem t e.types) types) patterns;

  # --- Pattern Extraction ---------------------------------------------------
  getPatterns = entries: builtins.map (e: e.pattern) entries;
}
