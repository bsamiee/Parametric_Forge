# Title         : oci-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/oci-tools.nix
# ----------------------------------------------------------------------------
# OCI image inspection, manipulation, and linting tools
{pkgs, ...}: {
  home.packages = with pkgs; [
    skopeo # Copy/inspect images between registries
    crane # Fast registry operations
    oras # Push/pull arbitrary OCI artifacts
    regctl # Registry inspection and tag/referrers management
    cosign # OCI image and artifact signing
    notation # Notary Project signature verification for OCI artifacts
    syft # SBOM generation for images and filesystems
    trivy # Image/config vulnerability scanner; do not run DB downloads in read-only checks
    grype # Vulnerability scanner; keep DB updates out of provisioning/check paths
    dive # Image layer analyzer
    hadolint # Dockerfile linter
    lazydocker # Docker TUI
  ];
}
