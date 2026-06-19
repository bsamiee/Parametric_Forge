# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/default.nix
# ----------------------------------------------------------------------------
# Container and Kubernetes tooling aggregator
{...}: {
  imports = [
    ./colima.nix
    ./kubectl.nix
    ./kustomize.nix
    ./helm.nix
    # ./argocd.nix  # Disabled from the default profile; build the current nixpkgs package before re-enabling.
    ./kubeseal.nix
    ./k9s.nix
    ./k8s-debug.nix
    ./oci-tools.nix
  ];
}
