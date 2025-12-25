# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/default.nix
# ----------------------------------------------------------------------------
# Environment aggregator + XDG base directories
{...}: {
  imports = [
    ./core.nix
    ./shell.nix
    ./languages.nix
    ./development.nix
    ./applications.nix
    ./containers.nix
    ./media.nix
    # secrets.nix merged into programs/shell-tools/1password.nix
  ];
}
