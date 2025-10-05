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
    ./aria2.nix
    ./archivemount.nix
    ./atuin.nix
    ./bandwhich.nix
    ./bat.nix
    ./bottom.nix
    ./carapace.nix
    ./choose.nix
    ./curlie.nix
    ./doggo.nix
    ./dua.nix
    ./duf.nix
    ./dust.nix
    ./eza.nix
    ./fastfetch.nix
    ./fd.nix
    ./fzf.nix
    ./gping.nix
    ./hexyl.nix
    ./hyperfine.nix
    ./jnv.nix
    ./lazyssh.nix
    ./ouch.nix
    ./p7zip.nix
    ./pik.nix
    ./procs.nix
    ./rclone.nix
    ./ripgrep.nix
    ./rsync.nix
    ./sd.nix
    ./serpl.nix
    ./speedtest.nix
    ./ssh.nix
    ./starship.nix
    ./tlrc.nix
    ./tokei.nix
    ./trash.nix
    ./trippy.nix
    ./watchexec.nix
    ./xh.nix
    ./zoxide.nix
  ];
}
