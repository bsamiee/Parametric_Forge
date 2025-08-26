# Title         : devops.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/01.packages/devops.nix
# ----------------------------------------------------------------------------
# DevOps tools for containers, orchestration, and infrastructure.

{
  pkgs,
  ...
}:

with pkgs;
[
  # --- Git Ecosystem Tools --------------------------------------------------
  # gh → Managed by programs.gh in git-tools.nix
  # lazygit → Managed by programs.lazygit in git-tools.nix
  gitAndTools.git-extras # Extra git commands (use git changelog instead of git-cliff)
  git-secret # Encrypt secrets in git
  git-crypt # Transparent file encryption in git
  gitleaks # Secret scanner for git repos
  gitAndTools.bfg-repo-cleaner # BFG Repo Cleaner

  # --- Container & Orchestration --------------------------------------------
  docker-client # Docker CLI
  docker-compose # Docker Compose for multi-container apps
  colima # Container runtimes on macOS
  podman # Docker alternative
  dive # Docker image explorer
  # lazydocker → Managed by programs.lazydocker in container-tools.nix
  buildkit # Next-gen container builder
  hadolint # Dockerfile linter

  # --- Build Tools ----------------------------------------------------------
  cmake # Cross-platform build system
  pkg-config # Helper tool for compiling applications

  # --- Testing & Automation -------------------------------------------------
  bats # Bash testing framework
  entr # File watcher for auto-running commands

  # --- Backup & Sync --------------------------------------------------------
  restic # Fast, secure backup program
  rclone # Cloud storage sync
]
