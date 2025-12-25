# Title         : kustomize.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/kustomize.nix
# ----------------------------------------------------------------------------
# Kubernetes native configuration management
{pkgs, ...}: {
  home.packages = [pkgs.kustomize];
}
