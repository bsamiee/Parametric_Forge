# Title         : system.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/system.nix
# ----------------------------------------------------------------------------
# Root-scope system defaults (loginwindow, Software Update) and the GUI launchd environment; user-scope defaults live in the home scope
# under forge.userDefaults, which imports each domain only when it changes.
{
  config,
  forgeToolchainEnvFor,
  lib,
  ...
}: let
  inherit (config.system) primaryUser;
  primaryUserHome = config.users.users.${primaryUser}.home;
  # System scope has no config.xdg; these bindings carry the literals the home scope derives (modules/home/xdg.nix, xdg.enable).
  configHome = "${primaryUserHome}/.config";
  cacheHome = "${primaryUserHome}/.cache";
  dataHome = "${primaryUserHome}/.local/share";
  stateHome = "${primaryUserHome}/.local/state";
  toolchainEnv = forgeToolchainEnvFor {
    home = primaryUserHome;
    username = primaryUser;
    xdgCacheHome = cacheHome;
    xdgConfigHome = configHome;
    xdgDataHome = dataHome;
    xdgStateHome = stateHome;
  };
in {
  system.defaults = {
    # --- [LOGIN_WINDOW]
    loginwindow = {
      SHOWFULLNAME = true; # Name+password fields, never the user icon list
      GuestEnabled = false;
      autoLoginUser = null;
      # LoginwindowText stays unset — a set value duplicates the name display
      ShutDownDisabled = false;
      SleepDisabled = false;
      RestartDisabled = false;
      ShutDownDisabledWhileLoggedIn = false;
      PowerOffDisabledWhileLoggedIn = false;
      RestartDisabledWhileLoggedIn = false;
      DisableConsoleAccess = false;
    };
    # --- [SOFTWARE_UPDATES]
    # Downloads stay automatic (the pane's default); an automatic install reboots the machine under a running build or agent session.
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;
  };

  # --- [POWER]
  # Idle minutes until the displays sleep (systemsetup): `pmset -g custom` carries the row under AC Power, while Battery Power keeps macOS's
  # own 2-minute default; the screen lock delay stays sysadminctl's.
  power.sleep.display = 30;

  # --- [PROFILES]
  # The login-shell profile list (PATH, NIX_PROFILES, fpath, XDG_*_DIRS through set-environment): the per-user packages profile Home Manager
  # fills under useUserPackages, the system profile, and the default profile. nix-darwin's own list also carries ~/.nix-profile, which
  # use-xdg-base-directories (modules/common/nix.nix) moves under $XDG_STATE_HOME/nix and useUserPackages leaves empty — a dead PATH segment.
  environment.profiles = lib.mkForce ["/etc/profiles/per-user/$USER" "/run/current-system/sw" "/nix/var/nix/profiles/default"];

  # --- [APPLICATION_FIREWALL]
  # Off, with signed software allowed to accept connections: the localhost listeners here are unsigned nix and mise binaries, which an enabled
  # firewall would prompt for one by one.
  networking.applicationFirewall = {
    enable = false;
    allowSigned = true;
    allowSignedApp = true;
  };

  # .NET's install-location registration: the host and VS Code's .NET Install Tool read this file for the install root when no `dotnet` is
  # resolvable from their own working directory (the Install Tool probes from its extension directory, where a mise shim has no version in
  # scope). It names mise's shared SDK store, never an SDK: each repository's global.json still selects the version. Root scope by design,
  # the file lives under /etc.
  environment.etc."dotnet/install_location_arm64".text = "${primaryUserHome}/.local/share/mise/dotnet-root\n";

  # Keep GUI-launched processes aligned with Nix/Home Manager PATH, so a tool in the shell also resolves in app-launched subprocesses.
  launchd.user.envVariables =
    toolchainEnv.scientificSessionEnv
    // toolchainEnv.launchdEnv
    // {
      PATH = toolchainEnv.launchdPathEntries;
      # The GUI domain carries no locale by default, so a Dock-launched process and every child it spawns runs under the C locale; the shell's
      # own LANG row (environments/core.nix) reaches only its descendants.
      LANG = "en_US.UTF-8";
      # The XDG base directories the home scope exports through hm-session-vars; a GUI-launched process (a mise shim under VS Code, a Dock-launched
      # agent) resolves the same roots as a login shell instead of each tool's own default.
      XDG_CONFIG_HOME = configHome;
      XDG_CACHE_HOME = cacheHome;
      XDG_DATA_HOME = dataHome;
      XDG_STATE_HOME = stateHome;
      # The colima and docker-cli home-manager modules derive these; the GUI domain carries the same values.
      inherit (config.home-manager.users.${primaryUser}.home.sessionVariables) DOCKER_HOST COLIMA_HOME DOCKER_CONFIG;
    };
}
