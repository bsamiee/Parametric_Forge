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
    # --- Login Window -------------------------------------------------------
    loginwindow = {
      SHOWFULLNAME = true; # Name+password fields, never the user icon list
      GuestEnabled = false;
      autoLoginUser = null;
      # LoginwindowText should not be set to avoid duplicate name display
      ShutDownDisabled = false;
      SleepDisabled = false;
      RestartDisabled = false;
      ShutDownDisabledWhileLoggedIn = false;
      PowerOffDisabledWhileLoggedIn = false;
      RestartDisabledWhileLoggedIn = false;
      DisableConsoleAccess = false;
    };
    # --- Activity Monitor ---------------------------------------------------
    ActivityMonitor = {
      ShowCategory = mkDefault 100;
      IconType = mkDefault 0;
      SortColumn = mkDefault "CPUUsage";
      SortDirection = mkDefault 0;
      OpenMainWindow = mkDefault true;
    };
    # --- Screenshots --------------------------------------------------------
    screencapture = {
      location = mkDefault "${primaryUserHome}/Downloads";
      type = mkDefault "png";
      disable-shadow = mkDefault true;
      include-date = mkDefault true;
      show-thumbnail = mkDefault false;
      target = mkDefault "file";
    };
    # --- Menu Bar Clock -----------------------------------------------------
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
    # --- System Services ----------------------------------------------------
    smb = {
      NetBIOSName = mkDefault null;
      ServerDescription = mkDefault null;
    };
    LaunchServices = {
      LSQuarantine = mkDefault false;
    };
    # --- Accessibility ------------------------------------------------------
    universalaccess = {
      closeViewScrollWheelToggle = mkDefault false;
      closeViewZoomFollowsFocus = mkDefault false;
      reduceMotion = mkDefault false;
      reduceTransparency = mkDefault false;
      mouseDriverCursorSize = mkDefault 0.85;
    };
    # --- Software Updates ---------------------------------------------------
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = mkDefault true;
    };
    # --- Global System Behavior ---------------------------------------------
    NSGlobalDomain = {
      "com.apple.sound.beep.volume" = mkDefault null;
      "com.apple.sound.beep.feedback" = mkDefault 0;
    };
    # --- Application-Specific System Settings -------------------------------
    CustomUserPreferences = {
      "com.apple.Terminal" = {
        SecureKeyboardEntry = mkDefault false;
      };
    };
  };

  # Keep GUI-launched processes aligned with Nix/Home Manager PATH behavior.
  # This avoids "tool exists in shell but not in app-launched subprocesses".
  launchd.user.envVariables =
    toolchainEnv.scientificSessionEnv
    // {
      PATH = toolchainEnv.launchdPathEntries;
      DOCKER_HOST = "unix://${primaryUserHome}/.local/share/colima/default/docker.sock";
      COLIMA_HOME = "${primaryUserHome}/.local/share/colima";
      DOCKER_CONFIG = "${primaryUserHome}/.config/docker";
      GH_CONFIG_DIR = "${primaryUserHome}/.config/gh";
      PNPM_HOME = "${primaryUserHome}/.local/share/pnpm";
      PUPPETEER_EXECUTABLE_PATH = toolchainEnv.puppeteerExecutablePath;
      PAGER = "less";
      GH_PAGER = "delta";
      GIT_PAGER = "delta";
      LESS = "-RFX";
    };
}
