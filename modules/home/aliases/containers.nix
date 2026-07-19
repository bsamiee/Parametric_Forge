# Title         : containers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/containers.nix
# ----------------------------------------------------------------------------
# Container and Kubernetes register rows.
{
  docker = [
    ["dps" "docker ps" "Running containers"]
    ["di" "docker images" "List images"]
    ["dcp" "docker compose" "Compose shorthand"]
  ];
  kube-debug = [
    ["klog" "stern" "Multi-pod log tailing"]
    ["kcap" "kube-capacity" "Resource usage"]
    ["ktree" "kubectl-tree" "Object hierarchy"]
    ["kneat" "kubectl-neat" "Clean YAML output"]
  ];
  kubernetes = [
    ["k" "kubecolor" "Colorized kubectl"]
    ["kx" "kubectx" "Switch context"]
    ["kn" "kubens" "Switch namespace"]
    ["kgp" "kubectl get pods" "List pods"]
    ["kl" "kubectl logs -f" "Follow pod logs"]
    ["k9" "k9s" "Kubernetes TUI"]
  ];
}
