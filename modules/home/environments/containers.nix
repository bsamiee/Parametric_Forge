# Title         : containers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/containers.nix
# ----------------------------------------------------------------------------
# Container and virtualization environment variables

{ config, ... }:

{
  home.sessionVariables = {
    # --- Docker --------------------------------------------------------------
    MACHINE_STORAGE_PATH = "${config.xdg.dataHome}/docker-machine";
    DOCKER_CERT_PATH = "${config.xdg.dataHome}/docker/certs";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";

    # --- Podman --------------------------------------------------------------
    CONTAINERS_REGISTRIES_CONF = "${config.xdg.configHome}/containers/registries.conf";
    CONTAINERS_STORAGE_CONF = "${config.xdg.configHome}/containers/storage.conf";
    CONTAINERS_CONF = "${config.xdg.configHome}/containers/containers.conf";

    # --- Colima --------------------------------------------------------------
    COLIMA_HOME = "${config.xdg.dataHome}/colima";

    # --- Container Tools -----------------------------------------------------
    LAZYDOCKER_CONFIG_DIR = "${config.xdg.configHome}/lazydocker";
    HADOLINT_CONFIG = "${config.xdg.configHome}/hadolint.yaml";
    DIVE_CONFIG = "${config.xdg.configHome}/dive/config.yaml";
  };
}
