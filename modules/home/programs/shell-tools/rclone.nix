# Title         : rclone.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/rclone.nix
# ----------------------------------------------------------------------------
# Cloud storage synchronization and management

{ lib, ... }:

{
  programs.rclone = {
    enable = true;
    # Configuration file managed at ~/.config/rclone/rclone.conf
    # Additional remotes and settings can be configured declaratively here
  };
}
