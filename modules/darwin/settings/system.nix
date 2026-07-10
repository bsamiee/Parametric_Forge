# Title         : system.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/system.nix
# ----------------------------------------------------------------------------
# Core system behavior, services, and default application settings.
{
  lib,
  config,
  forgeToolchainEnvFor,
  ...
}: let
  inherit (lib) mkDefault;
  inherit (config.system) primaryUser;
  primaryUserHome = config.users.users.${primaryUser}.home;
  toolchainEnv = forgeToolchainEnvFor {
    home = primaryUserHome;
    username = primaryUser;
    xdgCacheHome = "${primaryUserHome}/.cache";
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
    # --- [ACTIVITY_MONITOR]
    ActivityMonitor = {
      ShowCategory = mkDefault 100;
      IconType = mkDefault 0;
      SortColumn = mkDefault "CPUUsage";
      SortDirection = mkDefault 0;
      OpenMainWindow = mkDefault true;
    };
    # --- [SCREENSHOTS]
    screencapture = {
      location = mkDefault "${primaryUserHome}/Downloads";
      type = mkDefault "png";
      disable-shadow = mkDefault true;
      include-date = mkDefault true;
      show-thumbnail = mkDefault false;
      target = mkDefault "file";
    };
    # --- [MENU_BAR_CLOCK]
    menuExtraClock = {
      Show24Hour = mkDefault true;
      ShowAMPM = mkDefault null;
      ShowDate = mkDefault 1;
      ShowDayOfMonth = mkDefault true;
      ShowDayOfWeek = mkDefault true;
      ShowSeconds = mkDefault false;
      FlashDateSeparators = mkDefault false;
      IsAnalog = mkDefault false;
    };
    # --- [SYSTEM_SERVICES]
    smb = {
      NetBIOSName = mkDefault null;
      ServerDescription = mkDefault null;
    };
    LaunchServices = {
      LSQuarantine = mkDefault false;
    };
    # --- [ACCESSIBILITY]
    universalaccess = {
      closeViewScrollWheelToggle = mkDefault false;
      closeViewZoomFollowsFocus = mkDefault false;
      reduceMotion = mkDefault false;
      reduceTransparency = mkDefault false;
      mouseDriverCursorSize = mkDefault 1.0; # 1.0 is the floor; 0.85 was clamped
    };
    # --- [SOFTWARE_UPDATES]
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = mkDefault true;
    };
    # --- [GLOBAL_SYSTEM_BEHAVIOR]
    NSGlobalDomain = {
      "com.apple.sound.beep.volume" = mkDefault null;
      "com.apple.sound.beep.feedback" = mkDefault 0;
    };
    # --- [APPLICATION_SPECIFIC_SYSTEM_SETTINGS]
    CustomUserPreferences = {
      "com.apple.Terminal" = {
        SecureKeyboardEntry = mkDefault false;
      };
    };
  };

  # Keep GUI-launched processes aligned with Nix/Home Manager PATH, so a tool in the shell also resolves in app-launched subprocesses.
  launchd.user.envVariables =
    toolchainEnv.scientificSessionEnv
    // {
      PATH = toolchainEnv.launchdPathEntries;
      DOCKER_HOST = "unix://${primaryUserHome}/.local/share/colima/default/docker.sock";
      COLIMA_HOME = "${primaryUserHome}/.local/share/colima";
      DOCKER_CONFIG = "${primaryUserHome}/.config/docker";
      GH_CONFIG_DIR = "${primaryUserHome}/.config/gh";
      # Dock/Finder-launched WezTerm never sees shell sessionVariables; without these rows the GUI runtime (gui-sock, agent links, logs) lands in
      # XDG data instead of the declared XDG state root.
      WEZTERM_RUNTIME_DIR = "${primaryUserHome}/.local/state/wezterm";
      WEZTERM_LOG_DIR = "${primaryUserHome}/.local/state/wezterm";
      PNPM_HOME = "${primaryUserHome}/.local/share/pnpm";
      PUPPETEER_EXECUTABLE_PATH = toolchainEnv.puppeteerExecutablePath;
      PAGER = "less";
      GH_PAGER = "delta";
      GIT_PAGER = "delta";
      LESS = "-RFX";
    };
}
