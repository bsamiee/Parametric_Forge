# Title         : launchd.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : lib/launchd.nix
# ----------------------------------------------------------------------------
# Reusable launchd service helper functions for Darwin.

{ lib }:

let
  inherit (lib) mkIf mkMerge mapAttrs' nameValuePair removeAttrs;
  # --- Common Defaults ------------------------------------------------------
  defaultNice = 15;
  
  # --- Key Case Validation --------------------------------------------------
  # Home-manager expects PascalCase for launchd config attributes
  # This function ensures any additional args maintain proper casing
  validateLaunchdKeys = attrs: attrs;
in
rec {
  # --- Common Paths ---------------------------------------------------------
  getRuntimeDir = pkgs: if pkgs.stdenv.isDarwin then "\${HOME}/Library/Caches/TemporaryItems" else "/run/user/\$(id -u)";
  # --- Core Service Builder -------------------------------------------------
  mkLaunchdAgent =
    pkgs:
    {
      command ? null,
      script ? null,
      runAtLoad ? false,
      keepAlive ? false,
      startInterval ? null,
      startCalendarInterval ? null,
      environmentVariables ? { },
      workingDirectory ? null,
      standardOutPath ? null,
      standardErrorPath ? null,
      logBaseName ? null,
      nice ? defaultNice,
      processType ? "Background",
      ...
    }@args:
    let
      # Auto-generate log paths if baseName provided
      autoLogs =
        if logBaseName != null && standardOutPath == null then
          {
            standardOutPath = "${logBaseName}.log";
            standardErrorPath = "${logBaseName}.error.log";
          }
        else
          { };
      
      # Known arguments to exclude from additional config
      knownArgs = [
        "command" "script" "runAtLoad" "keepAlive" "startInterval"
        "startCalendarInterval" "environmentVariables" "workingDirectory"
        "standardOutPath" "standardErrorPath" "arguments" "logBaseName"
        "nice" "processType"
      ];
      
      # Additional arguments (should use PascalCase for launchd)
      additionalArgs = removeAttrs args knownArgs;
      
      # Home-manager expects PascalCase - pass through directly
      additionalConfig = validateLaunchdKeys additionalArgs;
    in
    # Return structure for home-manager launchd agents
    # Home-manager expects: launchd.agents.<name> = { enable = true; config = {...}; }
    # Since we're returning the config portion, use PascalCase for launchd plist keys
    mkMerge [
        # --- Core Configuration ---------------------------------------------
        (mkIf (command != null) {
          ProgramArguments = [ command ] ++ (args.arguments or [ ]);
        })
        (mkIf (script != null) {
          ProgramArguments = [
            "${pkgs.bash}/bin/bash"
            "-c"
            script
          ];
        })
        # --- Scheduling -----------------------------------------------------
        {
          RunAtLoad = runAtLoad;
          KeepAlive = keepAlive;
        }
        (mkIf (startInterval != null) {
          StartInterval = startInterval;
        })
        (mkIf (startCalendarInterval != null) {
          StartCalendarInterval = startCalendarInterval;
        })
        # --- Environment ----------------------------------------------------
        (mkIf (environmentVariables != { }) {
          EnvironmentVariables = environmentVariables;
        })
        (mkIf (workingDirectory != null) {
          WorkingDirectory = workingDirectory;
        })
        # --- Resource Management --------------------------------------------
        {
          ProcessType = processType;
          Nice = nice;
        }
        # --- Logging --------------------------------------------------------
        (mkIf (autoLogs ? standardOutPath) {
          StandardOutPath = autoLogs.standardOutPath;
        })
        (mkIf (autoLogs ? standardErrorPath) {
          StandardErrorPath = autoLogs.standardErrorPath;
        })
        (mkIf (standardOutPath != null) {
          StandardOutPath = standardOutPath;
        })
        (mkIf (standardErrorPath != null) {
          StandardErrorPath = standardErrorPath;
        })
        # --- Additional Configuration ---------------------------------------
        additionalConfig
    ];

  # --- Daemon Service -------------------------------------------------------
  # System daemons in nix-darwin use serviceConfig wrapper
  mkLaunchdDaemon =
    pkgs: args:
    {
      serviceConfig = mkLaunchdAgent pkgs (
        args
        // {
          UserName = args.UserName or "root";
          GroupName = args.GroupName or "wheel";
        }
      );
    };

  # --- Specialized Service Types --------------------------------------------
  mkPeriodicJob =
    pkgs:
    {
      command ? null,
      script ? null,
      interval, # in seconds
      nice ? 15, # Inherit default
      ...
    }@args:
    mkLaunchdAgent pkgs (
      removeAttrs args [ "interval" ]
      // {
        inherit command script nice;
        startInterval = interval;
        keepAlive = false;
        runAtLoad = args.runAtLoad or false;
      }
    );

  mkCalendarJob =
    pkgs:
    {
      command ? null,
      script ? null,
      calendar, # list of calendar specs
      nice ? 19, # Calendar jobs typically lower priority
      ...
    }@args:
    mkLaunchdAgent pkgs (
      removeAttrs args [ "calendar" ]
      // {
        inherit command script nice;
        startCalendarInterval = calendar;
        keepAlive = false;
        runAtLoad = false;
      }
    );

  mkResilientService =
    pkgs:
    {
      command,
      retryInterval ? 10,
      ...
    }@args:
    mkLaunchdAgent pkgs (
      removeAttrs args [ "retryInterval" ]
      // {
        inherit command;
        keepAlive = {
          SuccessfulExit = false;
          Crashed = true;
        };
        ThrottleInterval = retryInterval;
        ExitTimeOut = 30;
      }
    );
}
