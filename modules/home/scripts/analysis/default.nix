# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/analysis/default.nix
# ----------------------------------------------------------------------------
# Code-analysis scripts aggregator
{...}: {
  imports = [
    ./scc
  ];
}
