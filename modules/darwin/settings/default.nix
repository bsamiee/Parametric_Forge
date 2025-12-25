# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/default.nix
# ----------------------------------------------------------------------------
# Darwin settings aggregator
{...}: {
  imports = [
    ./input.nix
    ./interface.nix
    ./security.nix
    ./system.nix
  ];
}
