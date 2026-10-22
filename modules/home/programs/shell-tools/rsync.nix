# Title         : rsync.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/rsync.nix
# ----------------------------------------------------------------------------
# rsync package. A move that removes emptied source directories is `rclone move --delete-empty-src-dirs` (aliases/core.nix `rcmv`).
{pkgs, ...}: {
  home.packages = [pkgs.rsync];
}
