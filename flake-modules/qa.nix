# Title         : qa.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : flake-modules/qa.nix
# ----------------------------------------------------------------------------
# Flake check owner aggregator.
_: {
  imports = [
    ./qa/static.nix
  ];
}
