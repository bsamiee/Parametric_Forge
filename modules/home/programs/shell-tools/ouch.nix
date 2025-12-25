# Title         : ouch.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/ouch.nix
# ----------------------------------------------------------------------------
# Universal compression and decompression CLI tool
{pkgs, ...}: {
  home.packages = [pkgs.ouch];
}
