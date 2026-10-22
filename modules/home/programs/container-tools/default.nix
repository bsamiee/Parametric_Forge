# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/default.nix
# ----------------------------------------------------------------------------
# Runtime-less OCI registry and Dockerfile tool inventory.
{pkgs, ...}: {
  home.packages = [
    pkgs.crane # Fast registry operations
    pkgs.hadolint # Dockerfile linter; the nvim dockerfile lint lane
  ];
}
