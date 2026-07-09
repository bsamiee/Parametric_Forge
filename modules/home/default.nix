# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/default.nix
# ----------------------------------------------------------------------------
# Home Manager module aggregator
{...}: {
  imports = [
    ./assets
    ./environments
    ./theme.nix
    ./programs
    ./scripts
    ./xdg.nix
  ];
}
