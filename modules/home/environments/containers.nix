# Title         : containers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/containers.nix
# ----------------------------------------------------------------------------
# Registry and Kubernetes client environment: the containers/*.conf files and session paths the runtime-less OCI and cluster tools read.
{
  config,
  pkgs,
  ...
}: let
  toml = pkgs.formats.toml {};
in {
  home.sessionVariables = {
    # --- [CONTAINERS_IMAGE_AND_OCI_TOOLING]
    CONTAINERS_REGISTRIES_CONF = "${config.xdg.configHome}/containers/registries.conf";
    CONTAINERS_STORAGE_CONF = "${config.xdg.configHome}/containers/storage.conf";
    # Write-target: registry login materializes it; absent = anonymous. KUBECONFIG is a cross-surface row of modules/common/toolchain-env.nix.
    REGISTRY_AUTH_FILE = "${config.xdg.configHome}/containers/auth.json";

    # --- [KUBERNETES]
    K9S_CONFIG_DIR = "${config.xdg.configHome}/k9s";

    # --- [KUBECOLOR]
    KUBECOLOR_FORCE_COLORS = "auto";
  };

  xdg.configFile = {
    "containers/registries.conf".source = toml.generate "registries.conf" {unqualified-search-registries = ["docker.io"];};
    "containers/storage.conf".source = toml.generate "storage.conf" {storage = {};};
  };
}
