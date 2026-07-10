# Title         : nix-index.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/nix-index.nix
# ----------------------------------------------------------------------------
# Command-not-found with pre-built package database
_: {
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.nix-index-database.comma.enable = true;
}
