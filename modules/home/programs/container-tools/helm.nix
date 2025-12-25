# Title         : helm.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/helm.nix
# ----------------------------------------------------------------------------
# Kubernetes package manager with diff plugin
{pkgs, ...}: {
  home.packages = with pkgs; [
    kubernetes-helm # Helm v3
    kubernetes-helmPlugins.helm-diff # Diff plugin for upgrade previews
  ];
}
