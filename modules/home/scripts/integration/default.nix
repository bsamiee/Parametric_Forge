# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/scripts/integration/default.nix
# ----------------------------------------------------------------------------
# Integration scripts aggregator
{...}: {
  imports = [
    ./yazi
    ./zellij
    ./nvim
  ];
}
