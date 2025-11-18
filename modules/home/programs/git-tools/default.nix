# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/default.nix
# ----------------------------------------------------------------------------
# Git tools aggregator

{ lib, ... }:

{
  imports = [
    ./git.nix
    ./gh.nix
    ./git-quick-stats.nix
    ./lazygit.nix
    ./gitleaks.nix
  ];
}
