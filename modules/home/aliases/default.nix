# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/default.nix
# ----------------------------------------------------------------------------
# Shell aliases aggregator
{...}: {
  imports = [
    ./containers.nix
    ./core.nix
    ./git.nix
    ./media.nix
    ./nix.nix
  ];
}
