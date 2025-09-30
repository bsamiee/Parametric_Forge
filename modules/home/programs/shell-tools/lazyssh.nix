# Title         : lazyssh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/lazyssh.nix
# ----------------------------------------------------------------------------
# Terminal-based SSH manager for interactive server management

{ pkgs, ... }:

{
  home.packages = [ pkgs.lazyssh ];
}
