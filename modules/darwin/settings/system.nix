{
  config,
  lib,
  toolchainEnvFor,
  ...
}: let
  inherit (config.system) primaryUser;
  userHome = config.home-manager.users.${primaryUser};
  toolchainEnv = toolchainEnvFor {
    home = userHome.home.homeDirectory;
    username = primaryUser;
    xdgCacheHome = userHome.xdg.cacheHome;
    xdgConfigHome = userHome.xdg.configHome;
    xdgDataHome = userHome.xdg.dataHome;
    xdgStateHome = userHome.xdg.stateHome;
  };
in {
  system = {
    defaults = {
      # --- [LOGIN_WINDOW]
      loginwindow = {
        SHOWFULLNAME = true;
        autoLoginUser = primaryUser;
      };
      # --- [SOFTWARE_UPDATES]
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
      # --- [DOWNLOAD_QUARANTINE]
      LaunchServices.LSQuarantine = false;
    };

    # --- [LAUNCHD_USER_PATH_AND_STACK_BUFFER]
    activationScripts.postActivation.text = ''
      /bin/launchctl config user path ${lib.escapeShellArg config.environment.systemPath} >/dev/null
      if /usr/bin/tailspin info 2>&1 | /usr/bin/grep -q disabled; then
        /usr/bin/tailspin enable >/dev/null
      fi
    '';

    # --- [AGENT_LOG_ROTATION]
    newsyslog = {
      enable = true;
      files.forge-agents = map (logfilename: {
        inherit logfilename;
        owner = primaryUser;
        group = "staff";
        count = 3;
        size = "1024";
        flags = ["N"];
      }) (lib.unique (lib.mapAttrsToList (_: agent: agent.config.StandardOutPath) (lib.filterAttrs (_: agent: agent.enable && agent.config.StandardOutPath != null) userHome.launchd.agents)));
    };
  };

  # --- [POWER]
  power = {
    sleep = {
      display = 30;
      computer = "never";
    };
    restartAfterFreeze = true;
  };

  # --- [SHELL_ENVIRONMENT]
  environment = {
    profiles = lib.mkForce ["/etc/profiles/per-user/$USER" "/run/current-system/sw" "/nix/var/nix/profiles/default"];
    systemPath = lib.mkForce toolchainEnv.pathEntries;
    variables = toolchainEnv.sharedEnv;
    etc."dotnet/install_location_arm64".text = "${userHome.programs.mise.globalConfig.settings.dotnet.dotnet_root}\n";
  };

  # --- [OPEN_FILE_LIMIT]
  launchd.daemons.maxfiles.serviceConfig = {
    Label = "dev.bsamiee.maxfiles";
    ProgramArguments = ["/bin/launchctl" "limit" "maxfiles" "65536" "unlimited"];
    RunAtLoad = true;
  };

  # --- [APPLICATION_FIREWALL]
  networking.applicationFirewall.enable = false;
}
