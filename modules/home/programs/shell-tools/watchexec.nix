# Title         : watchexec.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/watchexec.nix
# ----------------------------------------------------------------------------
# watchexec package; each project's .gitignore and .ignore files steer what it watches.
{pkgs, ...}: {
  home.packages = [pkgs.watchexec];
}
