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
    ./choose.nix
    ./duf.nix
    ./dust.nix
    ./eza.nix
    ./fd.nix
    ./fzf.nix
    ./hyperfine.nix
    ./jq.nix
    ./ouch.nix
    ./procs.nix
    ./rclone.nix
    ./ripgrep.nix
    ./rsync.nix
    ./sd.nix
    ./ssh.nix
    ./tlrc.nix
    ./tokei.nix
    ./yq.nix
    ./trash.nix
    ./zoxide.nix
  ];
}
