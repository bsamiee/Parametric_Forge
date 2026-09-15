# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/default.nix
# ----------------------------------------------------------------------------
# Git tools owner: config modules plus the config-free package table
{pkgs, ...}: let
  manifest = import ../../../../overlays/manifest.nix;
  # Git-lane manifest admissions: git-cliff (changelog), mergiraf (structural merge driver; registration rides git.nix).
  gitRoster = map (row: pkgs.${row.attr}) (manifest.rosterRows "git");
in {
  imports = [
    ./git.nix
    ./gh.nix
    ./lazygit.nix
    ./gitleaks.nix
  ];

  # Manifest git-roster rows; difftastic reaches git through the difftool row's store path in git.nix.
  home.packages = gitRoster;
}
