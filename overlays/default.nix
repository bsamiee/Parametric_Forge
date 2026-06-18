# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/default.nix
# ----------------------------------------------------------------------------
# Package overlays
final: prev: {
  # Custom package overrides can be added here when needed
  duckdb = prev.callPackage ./duckdb {};
  rasm-provision = final.callPackage ./rasm-provision {};
  sqlean = prev.callPackage ./sqlean {};
}
