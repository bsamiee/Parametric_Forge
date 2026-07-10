# Title         : containers.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/environments/containers.nix
# ----------------------------------------------------------------------------
# Container runtime and OCI environment. services.colima + programs.docker-cli own DOCKER_HOST/COLIMA_HOME/DOCKER_CONFIG on Darwin; Linux talks
# to the system Docker socket unpointed with docker-cli owning config.json only.

{
  config,
  lib,
  pkgs,
  ...
}: let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  toml = pkgs.formats.toml {};
  # Guard keeps the agent inert when the Homebrew binary is absent.
  containerSystemStart = pkgs.writeShellApplication {
    name = "container-system-start";
    text = ''
      [[ -x /opt/homebrew/bin/container ]] || exit 0
      exec /opt/homebrew/bin/container system start --enable-kernel-install
    '';
  };
  # Apple Container startup config. `container system start` snapshots this into its app root and re-saves it, so the file must be a real
  # writable file — a store symlink fails the save and aborts the start.
  containerConfigToml = toml.generate "container-config.toml" {
    build = {
      rosetta = true;
      cpus = 4;
      memory = "8192mb";
    };
    container = {
      cpus = 4;
      memory = "4g";
    };
    registry.domain = "docker.io";
  };
in {
  # Declarative Colima: store-owned profile, launchd lifecycle (RunAtLoad + restart-on-clean-exit), session env. colimaHomeDir stays on dataHome —
  # the module default (configHome) would orphan the live VM. Intentional shutdown is `launchctl bootout` of the colima-default agent; a bare
  # `colima stop` re-triggers start. The VM+engine teardown needs minutes; launchd's default 20s ExitTimeOut SIGKILLs the stop mid-flight and
  # orphans the VM, so the window is widened to cover a full 8-container drain.
  launchd.agents.colima-default.config.ExitTimeOut = 300;

  # Apple Container autostart: `system start` registers the apiserver and helpers under the com.apple.container. launchd prefix and returns —
  # no keep-alive. Colima stays the DOCKER_HOST owner; this runtime is additive.
  launchd.agents.container-system = {
    enable = isDarwin;
    config = {
      ProgramArguments = [(lib.getExe containerSystemStart)];
      RunAtLoad = true;
    };
  };

  services.colima = {
    enable = isDarwin;
    colimaHomeDir = "${config.xdg.dataHome}/colima";
    profiles.default = {
      isActive = true; # docker context "colima" stays current
      isService = true; # launchd agent colima-default
      setDockerHost = true; # DOCKER_HOST=unix://$COLIMA_HOME/default/docker.sock
      settings = {
        cpu = 6;
        memory = 12;
        disk = 60; # grow-only resize; applied at next VM restart
        arch = "aarch64";
        runtime = "docker";
        vmType = "vz";
        rosetta = true;
        binfmt = true;
        mountType = "virtiofs";
        mountInotify = true;
        # The launchd-spawned start skips colima's implicit default mounts, leaving the guest without the home tree bind mounts resolve in.
        mounts = [
          {
            location = "~";
            writable = true;
          }
          {
            location = "/tmp/colima";
            writable = true;
          }
        ];
      };
    };
  };

  # Owns DOCKER_CONFIG and config.json on both platforms. NO credsStore: docker-credential-osxkeychain is a Docker-Desktop binary absent here;
  # empty inline auths are correct for Colima + public images. currentContext is injected by the colima module when the profile is active;
  # docker context meta stays Colima-owned — a store-owned meta.json breaks context creation.
  programs.docker-cli = {
    enable = true;
    configDir = "${config.xdg.configHome}/docker";
    settings.auths = {};
  };

  home.sessionVariables = {
    # --- [CONTAINERS_IMAGE_AND_OCI_TOOLING]
    CONTAINERS_REGISTRIES_CONF = "${config.xdg.configHome}/containers/registries.conf";
    CONTAINERS_STORAGE_CONF = "${config.xdg.configHome}/containers/storage.conf";
    CONTAINERS_CONF = "${config.xdg.configHome}/containers/containers.conf";
    # Write-targets: registry login and kind cluster-create materialize these; absent = anonymous/no cluster.
    REGISTRY_AUTH_FILE = "${config.xdg.configHome}/containers/auth.json";
    KUBECONFIG = "${config.xdg.configHome}/kube/config";

    # --- [KUBERNETES]
    K9S_CONFIG_DIR = "${config.xdg.configHome}/k9s";

    # --- [HELM]
    HELM_CONFIG_HOME = "${config.xdg.configHome}/helm";
    HELM_DATA_HOME = "${config.xdg.dataHome}/helm";
    HELM_CACHE_HOME = "${config.xdg.cacheHome}/helm";

    # --- [KUBECOLOR]
    KUBECOLOR_FORCE_COLORS = "auto";

    # --- [CONTAINER_TOOLS]
    LAZYDOCKER_CONFIG_DIR = "${config.xdg.configHome}/lazydocker";
  };

  # Forge owns the Apple Container config content; the file lands writable. A drifted app-root snapshot is cleared so the next
  # start re-copies it; kernel/vminit/network/dns stay upstream-owned.
  home.activation.appleContainerConfig = lib.mkIf isDarwin (lib.hm.dag.entryAfter ["writeBoundary"] ''
    run mkdir -p "${config.xdg.configHome}/container"
    run rm -f "${config.xdg.configHome}/container/config.toml"
    run cp ${containerConfigToml} "${config.xdg.configHome}/container/config.toml"
    run chmod 0644 "${config.xdg.configHome}/container/config.toml"
    appRootConfig="$HOME/Library/Application Support/com.apple.container/config/config.toml"
    if [[ -e "$appRootConfig" || -L "$appRootConfig" ]] && ! cmp -s ${containerConfigToml} "$appRootConfig"; then
      run rm -f "$appRootConfig"
    fi
  '');

  xdg.configFile = {
    "containers/registries.conf".source = toml.generate "registries.conf" {
      unqualified-search-registries = ["docker.io"];
      registry = [
        {
          prefix = "docker.io";
          location = "docker.io";
        }
      ];
    };
    "containers/storage.conf".source = toml.generate "storage.conf" {storage = {};};
    "containers/containers.conf".source = toml.generate "containers.conf" {
      containers = {};
      engine = {};
    };
  };
}
