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
      LSQuarantine = mkDefault false; # PERFORMANCE: Disable quarantine for downloaded apps
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
      AutomaticallyInstallMacOSUpdates = mkDefault true; # Auto-install system updates
    };
    # --- Spotlight Privacy Exclusions ----------------------------------------
    # Note: SpotlightServer option may not exist in current nix-darwin version
    # Spotlight exclusions handled via system activation script instead
    # --- Global System Behavior ---------------------------------------------
    NSGlobalDomain = {
      "com.apple.sound.beep.volume" = mkDefault null;
      "com.apple.sound.beep.feedback" = mkDefault 0;
    };
    # --- Application-Specific System Settings -------------------------------
    CustomUserPreferences = {
      # --- Spotlight Search Configuration -----------------------------------
      "com.apple.spotlight" = {
        orderedItems = [
          # --- Enabled: Essential functionality --------------------------------
          {
            name = "APPLICATIONS";
            enabled = 1;
          }
          {
            name = "SYSTEM_PREFS";
            enabled = 1;
          }
          {
            name = "DIRECTORIES";
            enabled = 1;
          }
          {
            name = "DOCUMENTS";
            enabled = 1;
          }
          {
            name = "PDF";
            enabled = 1;
          }
          # --- Disabled: Performance impact & privacy -----------------------
          {
            name = "IMAGES";
            enabled = 0;
          }
          {
            name = "SOURCE";
            enabled = 0;
          }
          {
            name = "MUSIC";
            enabled = 0;
          }
          {
            name = "MOVIES";
            enabled = 0;
          }
          {
            name = "PRESENTATIONS";
            enabled = 0;
          }
          {
            name = "SPREADSHEETS";
            enabled = 0;
          }
          {
            name = "MESSAGES";
            enabled = 0;
          }
          {
            name = "CONTACT";
            enabled = 0;
          }
          {
            name = "EVENT_TODO";
            enabled = 0;
          }
          {
            name = "BOOKMARKS";
            enabled = 0;
          }
          {
            name = "MENU_SPOTLIGHT_SUGGESTIONS";
            enabled = 0;
          }
          {
            name = "MENU_CONVERSION";
            enabled = 0;
          }
          {
            name = "MENU_EXPRESSION";
            enabled = 0;
          }
          {
            name = "MENU_DEFINITION";
            enabled = 0;
          }
          {
            name = "MENU_WEBSEARCH";
            enabled = 0;
          }
        ];
      };
      # --- Terminal Security Settings ---------------------------------------
      "com.apple.Terminal" = {
        SecureKeyboardEntry = mkDefault false;
      };
      # --- File Type Associations (Zen Browser) ------------------------------
      "com.apple.LaunchServices/com.apple.launchservices.secure" = {
        LSHandlers = [
          # Web URLs
          {
            LSHandlerContentType = "public.url";
            LSHandlerRoleAll = "app.zen-browser.zen";
          }
          {
            LSHandlerURLScheme = "http";
            LSHandlerRoleAll = "app.zen-browser.zen";
          }
          {
            LSHandlerURLScheme = "https";
            LSHandlerRoleAll = "app.zen-browser.zen";
          }
          {
            LSHandlerURLScheme = "ftp";
            LSHandlerRoleAll = "app.zen-browser.zen";
          }
          # Web files
          {
            LSHandlerContentType = "public.html";
            LSHandlerRoleAll = "app.zen-browser.zen";
          }
          {
            LSHandlerContentType = "public.xhtml";
            LSHandlerRoleAll = "app.zen-browser.zen";
          }
          # PDF files
          {
            LSHandlerContentType = "com.adobe.pdf";
            LSHandlerRoleAll = "com.adobe.Acrobat.Pro";
          }
        ];
      };
    };
  };
}
