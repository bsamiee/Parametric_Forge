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
    dive # Image layer analyzer
    hadolint # Dockerfile linter
    lazydocker # Docker TUI
  ];
}
