# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/files/default.nix
# ----------------------------------------------------------------------------
# File management aggregator

{ lib, pkgs, ... }:

{
  imports = [
    ./config_files.nix    # XDG config files
    ./home_files.nix      # Home root dotfiles
    ./data_files.nix      # XDG data files
    ./desktop_files.nix   # Linux desktop entries
  ];
}
