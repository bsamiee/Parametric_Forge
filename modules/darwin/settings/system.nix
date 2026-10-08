# Title         : system.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/system.nix
# ----------------------------------------------------------------------------
# Root-scope system defaults (loginwindow, Software Update); user-scope defaults live in the home scope under estate.userDefaults, which
# imports each domain only when it changes, and the GUI launchd environment replays from the home scope (environments/shell.nix).
{
  config,
  lib,
  ...
}: let
  inherit (config.system) primaryUser;
  # System scope has no config.xdg; this binding carries the literal the home scope derives (modules/home/xdg.nix, xdg.enable).
  dataHome = "${config.users.users.${primaryUser}.home}/.local/share";
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
  # Idle minutes until the displays sleep, and no system sleep (systemsetup): `pmset -g custom` carries both rows under AC Power, while Battery
  # Power keeps macOS's own defaults. Agent and build sessions hold no power assertion, so system sleep would suspend them mid-run, the same
  # stake that turns automatic installs off above; the screen lock delay stays sysadminctl's.
  power.sleep = {
    display = 30;
    computer = "never";
  };

  # --- [PROFILES]
  # The login-shell profile list (PATH, NIX_PROFILES, fpath, XDG_*_DIRS through set-environment): the per-user packages profile Home Manager
  # fills under useUserPackages, the system profile, and the default profile. nix-darwin's own list also carries ~/.nix-profile, which
  # use-xdg-base-directories (modules/common/nix.nix) moves under $XDG_STATE_HOME/nix and useUserPackages leaves empty — a dead PATH segment.
  environment.profiles = lib.mkForce ["/etc/profiles/per-user/$USER" "/run/current-system/sw" "/nix/var/nix/profiles/default"];

  # --- [SHELL_RESOURCES]
  # Concurrent Codex startup exceeds the inherited 256-file soft limit; new zsh children inherit this capacity without changing the hard limit
  programs.zsh.shellInit = ''
    ulimit -Sn 65536
  '';

  # --- [APPLICATION_FIREWALL]
  # Off, with signed software allowed to accept connections: the localhost listeners here are unsigned nix and mise binaries, which an enabled
  # firewall would prompt for one by one.
  networking.applicationFirewall = {
    enable = false;
    allowSigned = true;
    allowSignedApp = true;
  };

  # Install root the .NET host and VS Code's .NET Install Tool read when a mise shim finds no version from their working directory
  # Target is a link the mise postinstall hook (home/programs/shell-tools/mise.nix) points at an isolated SDK folder, never a version literal
  environment.etc."dotnet/install_location_arm64".text = "${dataHome}/mise/dotnet-current\n";
}
