# Title         : containers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/aliases/containers.nix
# ----------------------------------------------------------------------------
# Container and Kubernetes workflow aliases (surgical, no bloat)
_: {
  programs.zsh.shellAliases = {
    # --- Docker ---------------------------------------------------------------
    dps = "docker ps"; # List running containers
    di = "docker images"; # List images
    dcp = "docker compose"; # Compose shorthand

    # --- Kubernetes -----------------------------------------------------------
    k = "kubecolor"; # Colorized kubectl
    kx = "kubectx"; # Switch context
    kn = "kubens"; # Switch namespace
    kgp = "kubectl get pods"; # List pods
    kl = "kubectl logs -f"; # Follow pod logs
    k9 = "k9s"; # Launch TUI

    # --- ArgoCD ---------------------------------------------------------------
    argo = "argocd"; # ArgoCD CLI shorthand
    argosync = "argocd app sync"; # Sync application

    # --- Debug ----------------------------------------------------------------
    klog = "stern"; # Multi-pod log tailing
    kcap = "kube-capacity"; # Resource usage
    ktree = "kubectl-tree"; # Object hierarchy
    kneat = "kubectl-neat"; # Clean YAML output
  };
}
