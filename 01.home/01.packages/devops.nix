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
  # --- Container & Orchestration --------------------------------------------
  docker-client # Docker CLI for container management
  docker-compose # Docker Compose for multi-container applications
  colima # Container runtimes on macOS (Docker Desktop alternative)
  podman # Daemonless container engine (Docker alternative)
  dive # Docker image layer explorer and space analyzer
  # lazydocker → Managed by programs.lazydocker in container-tools.nix
  ctop # Container metrics and monitoring (like top for containers)
  buildkit # Next-generation container image builder
  hadolint # Dockerfile linter for best practices

  # --- CI/CD & Deployment ---------------------------------------------------
  # GitHub Actions, Jenkins, CircleCI tools would go here when available

  # --- Cloud & Infrastructure -----------------------------------------------
  # AWS CLI, Azure CLI, GCP CLI would go here when needed
  # Terraform, Pulumi, Ansible would go here when needed

  # --- Backup & Sync --------------------------------------------------------
  restic # Fast, secure, efficient backup program
  rclone # Cloud storage Swiss army knife - sync files to/from cloud
]
