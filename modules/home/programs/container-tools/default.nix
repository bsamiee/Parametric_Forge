# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/default.nix
# ----------------------------------------------------------------------------
# Container and Kubernetes tool inventory; imports carry real configuration only.
{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./k9s.nix
  ];

  # services.colima installs Colima, and containers.nix owns the runtime.
  home.packages = [
    pkgs.docker-buildx # Docker BuildKit builder subcommand
    pkgs.docker-client # CLI only (connects to Colima daemon)
    pkgs.docker-compose # Compose v2 plugin
    pkgs.lazydocker # Docker TUI

    # --- [KUBERNETES_CORE]
    (pkgs.wrapHelm pkgs.kubernetes-helm {plugins = [pkgs.kubernetes-helmPlugins.helm-diff];}) # Helm with the diff plugin registered on HELM_PLUGINS
    pkgs.k9s # Cluster TUI; config owned by k9s.nix
    pkgs.kind # Local Kubernetes clusters for disposable integration proof
    pkgs.kubecolor # Colorized kubectl output
    pkgs.kubectl # Kubernetes CLI
    pkgs.kubectx # Context/namespace switcher (includes kubens)

    # --- [KUBERNETES_DEBUG]
    pkgs.kube-capacity # Resource usage viewer
    pkgs.kubectl-neat # Clean YAML output (removes clutter)
    pkgs.kubectl-tree # Object hierarchy visualization
    pkgs.stern # Multi-pod log tailing

    # --- [OCI_REGISTRY]
    # Registry and image movement without a runtime (AGENTS.md routing): skopeo, crane, oras, regctl.
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
