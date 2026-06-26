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
    REGISTRY_AUTH_FILE = "${config.xdg.configHome}/containers/auth.json";

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

  xdg.configFile = {
    "containers/registries.conf".text = ''
      unqualified-search-registries = ["docker.io"]

      [[registry]]
      prefix = "docker.io"
      location = "docker.io"
    '';
    "containers/storage.conf".text = ''
      [storage]
    '';
    "containers/containers.conf".text = ''
      [containers]

      [engine]
    '';
    # Bring the active DOCKER_CONFIG (~/.config/docker) under Forge management so it cannot drift.
    # NO credsStore: docker-credential-osxkeychain is a Docker-Desktop binary absent on this Nix/Colima
    # machine, so naming it breaks every `docker pull` (helper-not-found). With no store, docker keeps
    # the (empty) auths inline — correct for Colima + public images. The legacy ~/.docker/config.json
    # (Docker-Desktop leftover) was cleared.
    "docker/config.json".text = builtins.toJSON {
      auths = {};
      currentContext = "colima";
    };
  };
}
