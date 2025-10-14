# Title         : op.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/op.nix
# ----------------------------------------------------------------------------
# 1Password CLI configuration

{ config, lib, pkgs, ... }:

{
  home.packages = [ pkgs._1password-cli ];

  home.activation.ensure1PasswordConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.xdg.configHome}/op"
    chmod 700 "${config.xdg.configHome}/op"
  '';
}