# Title         : colima.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/colima.nix
# ----------------------------------------------------------------------------
# Lightweight container runtime for macOS (Lima-based VM + Docker daemon)
{pkgs, ...}: {
  home.packages = with pkgs; [
    colima # VM manager running Docker/containerd
    docker-client # CLI only (connects to Colima daemon)
    docker-compose # Compose v2 plugin
  ];
}
