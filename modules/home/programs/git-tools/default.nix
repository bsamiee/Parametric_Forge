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

  # Config-free git estate tools plus manifest git-roster rows.
  home.packages =
    [
      pkgs.git-quick-stats
      pkgs.difftastic
    ]
    ++ gitRoster;
}
