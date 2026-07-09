# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/container-tools/default.nix
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

  # Colima itself is installed by services.colima (containers.nix owns the runtime).
  home.packages = [
    pkgs.docker-buildx # Docker BuildKit builder subcommand
    pkgs.docker-client # CLI only (connects to Colima daemon)
    pkgs.docker-compose # Compose v2 plugin
    pkgs.lazydocker # Docker TUI

    # --- Kubernetes Core --------------------------------------------------------
    (pkgs.wrapHelm pkgs.kubernetes-helm {plugins = [pkgs.kubernetes-helmPlugins.helm-diff];}) # Helm with the diff plugin registered on HELM_PLUGINS
    pkgs.k9s # Cluster TUI; config owned by k9s.nix
    pkgs.kind # Local Kubernetes clusters for disposable integration proof
    pkgs.kubecolor # Colorized kubectl output
    pkgs.kubectl # Kubernetes CLI
    pkgs.kubectx # Context/namespace switcher (includes kubens)
    pkgs.kubeseal # SealedSecrets client for encrypting secrets in git
    pkgs.kustomize # Kubernetes native manifest composition

    # --- Kubernetes Debug and Validation ----------------------------------------
    pkgs.conftest # OPA/Rego policy checks for config and manifests
    pkgs.kube-capacity # Resource usage viewer
    pkgs.kube-linter # Kubernetes manifest linter
    pkgs.kubeconform # Fast K8s manifest validator with CRD support
    pkgs.kubectl-cnpg # CloudNativePG kubectl plugin
    pkgs.kubectl-neat # Clean YAML output (removes clutter)
    pkgs.kubectl-tree # Object hierarchy visualization
    pkgs.kubescape # Kubernetes security posture scanner
    pkgs.pluto # Kubernetes API deprecation scanner
    pkgs.stern # Multi-pod log tailing

    # --- OCI Registry and Supply Chain ------------------------------------------
    pkgs.cosign # OCI image and artifact signing
    pkgs.crane # Fast registry operations
    pkgs.dive # Image layer analyzer
    pkgs.grype # Vulnerability scanner; keep DB updates out of provisioning/check paths
    pkgs.hadolint # Dockerfile linter
    pkgs.notation # Notary Project signature verification for OCI artifacts
    pkgs.oras # Push/pull arbitrary OCI artifacts
    pkgs.osv-scanner # Source/dependency vulnerability scanner
    pkgs.regctl # Registry inspection and tag/referrers management
    pkgs.skopeo # Copy/inspect images between registries
    pkgs.syft # SBOM generation for images and filesystems
    pkgs.trivy # Image/config vulnerability scanner; do not run DB downloads in read-only checks
  ];

  # Delegate kubecolor completions to kubectl (after carapace loads kubectl completions)
  programs.zsh.initContent = lib.mkAfter ''
    # --- Kubecolor Completion Delegation ----------------------------------------
    compdef kubecolor=kubectl
  '';
}
