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
    ./bandwhich.nix
    ./bat.nix
    ./bottom.nix
    ./broot.nix
    ./choose.nix
    ./doggo.nix
    ./duf.nix
    ./dust.nix
    ./eza.nix
    ./fd.nix
    ./fzf.nix
    ./gping.nix
    ./hyperfine.nix
    ./jq.nix
    ./ouch.nix
    ./procs.nix
    ./rclone.nix
    ./ripgrep.nix
    ./rsync.nix
    ./sd.nix
    ./speedtest.nix
    ./ssh.nix
    ./starship.nix
    ./tlrc.nix
    ./tokei.nix
    ./trash.nix
    ./trippy.nix
    ./xh.nix
    ./yq.nix
    ./zoxide.nix
  ];
}
