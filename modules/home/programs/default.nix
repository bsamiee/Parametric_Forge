# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/default.nix
# ----------------------------------------------------------------------------
# Home Manager programs aggregator
{...}: {
  imports = [
    ./apps
    ./container-tools
    ./git-tools
    ./languages
    ./mac-tools
    ./media-tools
    ./nix-tools
    ./shell-tools
    ./zsh
  ];
}
