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
    ./bottom.nix
    ./broot.nix
    ./delta.nix
    ./duf.nix
    ./dust.nix
    ./eza.nix
    ./fd.nix
    ./fzf.nix
    ./hyperfine.nix
    ./procs.nix
    ./ripgrep.nix
    ./sd.nix
    ./tlrc.nix
    ./tokei.nix
    ./trash.nix
    ./zoxide.nix
  ];
}
