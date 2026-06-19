# Title         : k8s-debug.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/k8s-debug.nix
# ----------------------------------------------------------------------------
# Kubernetes debugging, inspection, and validation tools
{pkgs, ...}: {
  home.packages = with pkgs; [
    stern # Multi-pod log tailing
    kube-capacity # Resource usage viewer
    kubectl-tree # Object hierarchy visualization
    kubectl-neat # Clean YAML output (removes clutter)
    kubeconform # Fast K8s manifest validator with CRD support
    kind # Local Kubernetes clusters for disposable integration proof
    kubectl-cnpg # CloudNativePG kubectl plugin
    pluto # Kubernetes API deprecation scanner
    kubent # Kubernetes API deprecation scanner
    conftest # OPA/Rego policy checks for config and manifests
    kube-score # Static Kubernetes object analysis
    kubescape # Kubernetes security posture scanner
    kube-linter # Kubernetes manifest linter
  ];
}
