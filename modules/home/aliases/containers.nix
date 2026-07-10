# Title         : containers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/containers.nix
# ----------------------------------------------------------------------------
# Container and Kubernetes register rows.
[
  # --- [DOCKER]
  {
    alias = "dps";
    expansion = "docker ps";
    desc = "Running containers";
    category = "docker";
  }
  {
    alias = "di";
    expansion = "docker images";
    desc = "List images";
    category = "docker";
  }
  {
    alias = "dcp";
    expansion = "docker compose";
    desc = "Compose shorthand";
    category = "docker";
  }
  # --- [KUBERNETES]
  {
    alias = "k";
    expansion = "kubecolor";
    desc = "Colorized kubectl";
    category = "kubernetes";
  }
  {
    alias = "kx";
    expansion = "kubectx";
    desc = "Switch context";
    category = "kubernetes";
  }
  {
    alias = "kn";
    expansion = "kubens";
    desc = "Switch namespace";
    category = "kubernetes";
  }
  {
    alias = "kgp";
    expansion = "kubectl get pods";
    desc = "List pods";
    category = "kubernetes";
  }
  {
    alias = "kl";
    expansion = "kubectl logs -f";
    desc = "Follow pod logs";
    category = "kubernetes";
  }
  {
    alias = "k9";
    expansion = "k9s";
    desc = "Kubernetes TUI";
    category = "kubernetes";
  }
  # --- [KUBE_DEBUG]
  {
    alias = "klog";
    expansion = "stern";
    desc = "Multi-pod log tailing";
    category = "kube-debug";
  }
  {
    alias = "kcap";
    expansion = "kube-capacity";
    desc = "Resource usage";
    category = "kube-debug";
  }
  {
    alias = "ktree";
    expansion = "kubectl-tree";
    desc = "Object hierarchy";
    category = "kube-debug";
  }
  {
    alias = "kneat";
    expansion = "kubectl-neat";
    desc = "Clean YAML output";
    category = "kube-debug";
  }
]
