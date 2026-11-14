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
      files.forge-agents =
        map (logfilename: {
          inherit logfilename;
          owner = primaryUser;
          group = "staff";
          count = 3;
          size = "1024";
          flags = ["N"];
        }) (lib.unique (lib.mapAttrsToList (_: agent: agent.config.StandardOutPath) (lib.filterAttrs (_: agent: agent.enable && agent.config.StandardOutPath != null) userHome.launchd.agents)
            ++ lib.mapAttrsToList (_: agent: agent.serviceConfig.StandardOutPath) config.launchd.user.agents));
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
    pathsToLink = ["/opt"];
    systemPath = lib.mkForce toolchainEnv.pathEntries;
    variables = toolchainEnv.sharedEnv;
    etc."dotnet/install_location_arm64".text = "${userHome.programs.mise.globalConfig.settings.dotnet.dotnet_root}\n";
  };

  # --- [PROTECTED_FILE_AGENTS]
  launchd.user.agents =
    lib.mapAttrs (name: row: {
      serviceConfig =
        {
          Label = "dev.bsamiee.${name}";
          ProgramArguments =
            [
              userHome.forge.shell
              "-c"
              ''/bin/wait4path ${builtins.storeDir} && /bin/ls ${lib.escapeShellArg "${userHome.home.homeDirectory}/Library/Biome"} >/dev/null 2>&1 || { print -r -- "$(/bin/date +%FT%T) $0: ${userHome.forge.shell} holds no Full Disk Access, skipped"; exit 0 }; "$@"; exit''
              name
            ]
            ++ row.argv;
          ProcessType = "Background";
          StandardOutPath = "${userHome.home.homeDirectory}/Library/Logs/${name}.log";
          StandardErrorPath = "${userHome.home.homeDirectory}/Library/Logs/${name}.log";
        }
        // removeAttrs row ["argv"];
    })
    userHome.forge.protectedAgents;

  # --- [APPLICATION_FIREWALL]
  networking.applicationFirewall.enable = false;
}
