# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : overlays/default.nix
# ----------------------------------------------------------------------------
# Package overlays

final: prev:
let
  # Pull in the upstream bleeding-edge yazi overlay so every system sees it.
  yaziOverlay = inputs.yazi.overlays.default final prev;
in
yaziOverlay // {
  # Custom package overrides can be added here when needed
  sqlean = prev.callPackage ./sqlean { };
}
