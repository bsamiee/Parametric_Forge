# Title         : op.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/op.nix
# ----------------------------------------------------------------------------
# 1Password CLI for secure secret management and authentication

{ config, lib, pkgs, ... }:

{
  # Install 1Password CLI
  home.packages = with pkgs; [ _1password-cli ];
}
