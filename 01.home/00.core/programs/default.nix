# Title         : 01.home/00.core/programs/default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/default.nix
# ----------------------------------------------------------------------------
# Aggregates all program configurations.

{ ... }:

{
  imports = [
    ./git-tools.nix
    ./shell-tools.nix
    ./ssh.nix
    ./zsh.nix
  ];
}
