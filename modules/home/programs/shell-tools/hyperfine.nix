# Title         : hyperfine.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/shell-tools/hyperfine.nix
# ----------------------------------------------------------------------------
# Command-line benchmarking tool
{pkgs, ...}: {
  home.packages = [pkgs.hyperfine];
}
