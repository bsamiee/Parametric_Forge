# Title         : modules/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/default.nix
# ----------------------------------------------------------------------------
# Module aggregator for single-point import of all custom modules.

{
  imports = [
    ./secrets.nix
  ];
}
