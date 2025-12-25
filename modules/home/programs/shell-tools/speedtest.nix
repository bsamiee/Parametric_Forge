# Title         : speedtest.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/speedtest.nix
# ----------------------------------------------------------------------------
# Official Ookla Speedtest CLI for internet speed testing
{pkgs, ...}: {
  home.packages = [pkgs.ookla-speedtest];
}
