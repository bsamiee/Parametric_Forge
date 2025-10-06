# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/default.nix
# ----------------------------------------------------------------------------
# Package overlays

{ inputs }:

final: prev: {
  # Custom package overrides can be added here when needed
  sqlean = prev.callPackage (inputs.self + "/overlays/sqlean") { };

  yaziPlugins = (prev.yaziPlugins or { }) // (prev.callPackage (inputs.self + "/overlays/yazi") { });
}
