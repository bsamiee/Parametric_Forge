# Title         : containers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/containers.nix
# ----------------------------------------------------------------------------
# Container and virtualization environment variables
{config, ...}: {
  home.sessionVariables = {
    # --- Docker -------------------------------------------------------------
    DOCKER_HOST = "unix://${config.xdg.dataHome}/colima/default/docker.sock";
    MACHINE_STORAGE_PATH = "${config.xdg.dataHome}/docker-machine";
    DOCKER_CERT_PATH = "${config.xdg.dataHome}/docker/certs";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";

    # --- Podman -------------------------------------------------------------
    CONTAINERS_REGISTRIES_CONF = "${config.xdg.configHome}/containers/registries.conf";
    CONTAINERS_STORAGE_CONF = "${config.xdg.configHome}/containers/storage.conf";
    CONTAINERS_CONF = "${config.xdg.configHome}/containers/containers.conf";

    # --- Colima -------------------------------------------------------------
    COLIMA_HOME = "${config.xdg.dataHome}/colima";

    # --- Kubernetes ---------------------------------------------------------
    KUBECONFIG = "${config.xdg.configHome}/kube/config";
    K9S_CONFIG_DIR = "${config.xdg.configHome}/k9s";

    # --- Helm -----------------------------------------------------------------
    HELM_CONFIG_HOME = "${config.xdg.configHome}/helm";
    HELM_DATA_HOME = "${config.xdg.dataHome}/helm";
    HELM_CACHE_HOME = "${config.xdg.cacheHome}/helm";

    # --- Kubecolor ------------------------------------------------------------
    KUBECOLOR_FORCE_COLORS = "auto";

    # --- Container Tools ----------------------------------------------------
    LAZYDOCKER_CONFIG_DIR = "${config.xdg.configHome}/lazydocker";
    HADOLINT_CONFIG = "${config.xdg.configHome}/hadolint.yaml";
    DIVE_CONFIG = "${config.xdg.configHome}/dive/config.yaml";
  };
}
