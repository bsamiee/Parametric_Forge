# Title         : git-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/git-tools.nix
# ----------------------------------------------------------------------------
# Git version control and related development tools.

{ pkgs, ... }:

with pkgs;
[
  # --- Core Git Tools -------------------------------------------------------
  # gh → Managed by programs.gh in git.nix
  # lazygit → Managed by programs.lazygit in git.nix
  gitAndTools.git-extras # Extra git commands (use git changelog instead of git-cliff)

  # --- Git Security & Secrets Management ------------------------------------
  git-crypt # Transparent file encryption in git
  gitleaks # Secret scanner for git repos - detect leaked credentials

  # --- Git Repository Management ---------------------------------------------
  gitAndTools.bfg-repo-cleaner # Remove large files/passwords from git history
]
