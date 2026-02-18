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
  ...
}: let
  inherit (lib) mkDefault;
  primaryUser = config.system.primaryUser;
  primaryUserHome = config.users.users.${primaryUser}.home;
in {
  system.defaults = {
    # --- Login Window -------------------------------------------------------
    loginwindow = {
      SHOWFULLNAME = true; # Show username/password fields instead of user icon list
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
  launchd.user.envVariables.PATH = [
    "${primaryUserHome}/.nix-profile/bin"
    "${primaryUserHome}/.local/bin"
    "${primaryUserHome}/bin"
    "${primaryUserHome}/.dotnet/tools"
    "${primaryUserHome}/.local/share/cargo/bin"
    "${primaryUserHome}/.local/share/go/bin"
    "${primaryUserHome}/.local/share/pnpm"
    "/etc/profiles/per-user/${primaryUser}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/Applications/Rhino 8.app/Contents/Resources/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];
}
