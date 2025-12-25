# Title         : nom.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/nix-tools/nom.nix
# ----------------------------------------------------------------------------
# Nix output monitor for beautiful build output
{pkgs, ...}: {
  home.packages = with pkgs; [
    nix-output-monitor
  ];
}
