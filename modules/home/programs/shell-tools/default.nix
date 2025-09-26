# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/default.nix
# ----------------------------------------------------------------------------
# Shell tools aggregator

{ lib, ... }:

{
  imports = [
    ./atuin.nix
    ./bat.nix
    ./broot.nix
    ./delta.nix
    ./eza.nix
    ./fd.nix
    ./fzf.nix
    ./ripgrep.nix
    ./sd.nix
    ./trash.nix
    ./zoxide.nix
  ];
}
