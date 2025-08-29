# Title         : 00.system/darwin/settings/system.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/settings/system.nix
# ----------------------------------------------------------------------------
# Core system behavior, services, and default application settings.

{ lib, context, ... }:

let
  inherit (lib) mkDefault;
in
{
  system.defaults = {
    # --- Login Window -------------------------------------------------------
    loginwindow = {
      SHOWFULLNAME = mkDefault true;
      GuestEnabled = mkDefault false;
      autoLoginUser = mkDefault null;
      LoginwindowText = mkDefault null;
      ShutDownDisabled = mkDefault false;
      SleepDisabled = mkDefault false;
      RestartDisabled = mkDefault false;
      ShutDownDisabledWhileLoggedIn = mkDefault false;
      PowerOffDisabledWhileLoggedIn = mkDefault false;
      RestartDisabledWhileLoggedIn = mkDefault false;
      DisableConsoleAccess = mkDefault true;
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
      location = mkDefault "${context.userHome}/Downloads";
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
      LSQuarantine = mkDefault null;
    };
    # --- Accessibility ------------------------------------------------------
    universalaccess = {
      closeViewScrollWheelToggle = mkDefault false;
      closeViewZoomFollowsFocus = mkDefault false;
      reduceMotion = mkDefault false;
      reduceTransparency = mkDefault false;
      mouseDriverCursorSize = mkDefault 0.9;
    };
    # --- Software Updates ---------------------------------------------------
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = mkDefault false;
    };
    # --- Global System Behavior ---------------------------------------------
    NSGlobalDomain = {
      "com.apple.sound.beep.volume" = mkDefault null;
      "com.apple.sound.beep.feedback" = mkDefault 0;
    };
    # --- Application-Specific System Settings -------------------------------
    CustomUserPreferences = {
      # --- Spotlight Search Configuration -----------------------------------
      "com.apple.spotlight" = {
        orderedItems =
          lib.map
            (name: {
              enabled = 0;
              inherit name;
            })
            [
              "APPLICATIONS"
              "SYSTEM_PREFS"
              "DIRECTORIES"
              "DOCUMENTS"
              "PDF"
              "IMAGES"
              "SOURCE"
              "MUSIC"
              "MOVIES"
              "PRESENTATIONS"
              "SPREADSHEETS"
              "MESSAGES"
              "CONTACT"
              "EVENT_TODO"
              "BOOKMARKS"
              "MENU_SPOTLIGHT_SUGGESTIONS"
              "MENU_CONVERSION"
              "MENU_EXPRESSION"
              "MENU_DEFINITION"
              "MENU_WEBSEARCH"
            ];
      };
      # --- Terminal Security Settings ---------------------------------------
      "com.apple.Terminal" = {
        SecureKeyboardEntry = mkDefault false;
      };
      # --- File Type Associations -------------------------------------------
      "com.apple.LaunchServices/com.apple.launchservices.secure" = {
        LSHandlers = [
          # --- Source Code & Development ------------------------------------
          {
            LSHandlerContentType = "public.source-code";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.plain-text";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.unix-executable";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.shell-script";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          # --- Web Development ----------------------------------------------
          {
            LSHandlerContentType = "public.json";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "com.netscape.javascript-source";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.xml";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.html";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.css";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          # --- Documentation & Configuration --------------------------------
          {
            LSHandlerContentType = "net.daringfireball.markdown";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.yaml";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "com.apple.property-list";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.toml";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          # --- Language Specific --------------------------------------------
          {
            LSHandlerContentType = "public.python-script";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.ruby-script";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.perl-script";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
          {
            LSHandlerContentType = "public.php-script";
            LSHandlerRoleAll = mkDefault "com.microsoft.vscode";
          }
        ];
      };
    };
  };
}
