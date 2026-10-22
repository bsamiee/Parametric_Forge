# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/default.nix
# ----------------------------------------------------------------------------
# Scripts module aggregator.
_: {
  imports = [./loc.nix ./terminal.nix];
}
