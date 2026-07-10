# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/default.nix
# ----------------------------------------------------------------------------
# Environment module aggregator

{...}: {
  imports = [
    ./core.nix
    ./shell.nix
    ./languages.nix
    ./development.nix
    ./applications.nix
    ./containers.nix
    ./media.nix
  ];
}
