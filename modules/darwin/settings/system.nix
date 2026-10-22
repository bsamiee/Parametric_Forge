# Title         : system.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/system.nix
# ----------------------------------------------------------------------------
# Root-scope system defaults (loginwindow, Software Update), the every-shell environment, and the launchd user PATH; user-scope defaults
# live in the home scope as Home Manager targets.darwin.defaults (mac-tools/defaults), imported on every switch, and the rest of the GUI
# launchd environment replays from the home scope (environments/shell.nix).
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
  system.defaults = {
    # --- [LOGIN_WINDOW]
    # Auto-login boots straight into the session so launchd agents resume after a restart; /etc/kcpassword is set once through
    # System Settings › Users & Groups › Automatically log in as.
    loginwindow = {
      SHOWFULLNAME = true; # Name+password fields, never the user icon list
      autoLoginUser = primaryUser;
    };
    # --- [SOFTWARE_UPDATES]
    # Downloads stay automatic (the pane's default); an automatic install reboots the machine under a running build or agent session.
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
  };

  # --- [POWER]
  # Idle minutes until the displays sleep, and no system sleep (systemsetup): `pmset -g custom` carries both rows under AC Power, while Battery
  # Power keeps macOS's own defaults. Agent and build sessions hold no power assertion, so system sleep would suspend them mid-run, the same
  # stake that turns automatic installs off above; the screen lock delay stays sysadminctl's.
  power.sleep = {
    display = 30;
    computer = "never";
  };

  # --- [SHELL_ENVIRONMENT]
  # set-environment is sourced by /etc/zshenv and /etc/bashrc, so every shell kind reads the one PATH vector and the cross-surface rows; the
  # plain-priority rows replace nix-darwin's EDITOR/PAGER defaults at their owner, and the vector replaces its profile-derived PATH.
  environment = {
    # The profile list set-environment reads for NIX_PROFILES (zsh fpath) and XDG_*_DIRS: the per-user packages profile Home Manager fills
    # under useUserPackages, the system profile, and the default profile. nix-darwin's own list also carries ~/.nix-profile, which
    # use-xdg-base-directories (modules/common/nix.nix) moves under $XDG_STATE_HOME/nix and useUserPackages leaves empty — a dead segment.
    profiles = lib.mkForce ["/etc/profiles/per-user/$USER" "/run/current-system/sw" "/nix/var/nix/profiles/default"];
    systemPath = lib.mkForce toolchainEnv.pathEntries;
    variables = toolchainEnv.sharedEnv;
  };

  # --- [LAUNCHD_USER_PATH]
  # launchd hands every user-domain process (Dock and Finder launches, launchd agents) the PATH `launchctl config user path` stores, read once
  # at boot, so a changed vector takes effect after the next reboot; `launchctl setenv PATH` never reaches them. The write is idempotent.
  system.activationScripts.postActivation.text = ''
    /bin/launchctl config user path ${lib.escapeShellArg config.environment.systemPath} >/dev/null
  '';

  # --- [SHELL_RESOURCES]
  # Concurrent Codex startup exceeds the inherited 256-file soft limit; new zsh children inherit this capacity without changing the hard limit
  programs.zsh.shellInit = ''
    ulimit -Sn 65536
  '';

  # --- [APPLICATION_FIREWALL]
  # Off: the localhost listeners here are unsigned nix and mise binaries, which an enabled firewall would prompt for one by one.
  networking.applicationFirewall.enable = false;

  # Install root the .NET host and VS Code's .NET Install Tool read when a mise shim finds no version from their working directory: the
  # shared root every mise SDK installs into (home/programs/shell-tools/mise.nix), each repository's global.json still selecting the SDK
  environment.etc."dotnet/install_location_arm64".text = "${userHome.programs.mise.globalConfig.settings.dotnet.dotnet_root}\n";
}
