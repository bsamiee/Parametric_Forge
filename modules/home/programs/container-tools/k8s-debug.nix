# Title         : k8s-debug.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/k8s-debug.nix
# ----------------------------------------------------------------------------
# Kubernetes debugging and inspection tools
{pkgs, ...}: {
  home.packages = with pkgs; [
    stern # Multi-pod log tailing
    kube-capacity # Resource usage viewer
    kubectl-tree # Object hierarchy visualization
    kubectl-neat # Clean YAML output (removes clutter)
  ];
}
