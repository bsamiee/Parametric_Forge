# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/default.nix
# ----------------------------------------------------------------------------
# Package overlays
_: _final: prev: {
  # Custom package overrides can be added here when needed
  duckdb = prev.callPackage ./duckdb {};
  sqlean = prev.callPackage ./sqlean {};
}
