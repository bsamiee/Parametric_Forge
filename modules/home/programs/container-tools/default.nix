# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/default.nix
# ----------------------------------------------------------------------------
# Kubernetes client and runtime-less OCI registry tool inventory; imports carry real configuration only.
{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./k9s.nix
  ];

  home.packages = [
    # --- [KUBERNETES_CORE]
    (pkgs.wrapHelm pkgs.kubernetes-helm {plugins = [pkgs.kubernetes-helmPlugins.helm-diff];}) # Helm with the diff plugin registered on HELM_PLUGINS
    pkgs.k9s # Cluster TUI; config owned by k9s.nix
    pkgs.kubecolor # Colorized kubectl output
    pkgs.kubectl # Kubernetes CLI
    pkgs.kubectx # Context/namespace switcher (includes kubens)

    # --- [KUBERNETES_DEBUG]
    pkgs.kube-capacity # Resource usage viewer
    pkgs.kubectl-neat # Clean YAML output (removes clutter)
    pkgs.kubectl-tree # Object hierarchy visualization
    pkgs.stern # Multi-pod log tailing

    # --- [OCI_REGISTRY]
    pkgs.crane # Fast registry operations
    pkgs.hadolint # Dockerfile linter; the nvim dockerfile lint lane
    pkgs.oras # Push/pull arbitrary OCI artifacts
    pkgs.regctl # Registry inspection and tag/referrers management
    pkgs.skopeo # Copy/inspect images between registries
  ];

  # Delegate kubecolor completions to kubectl (after carapace loads kubectl completions)
  programs.zsh.initContent = lib.mkAfter ''
    # --- [KUBECOLOR_COMPLETION_DELEGATION]
    compdef kubecolor=kubectl
  '';
}
