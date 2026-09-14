# Title         : system.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/defaults/system.nix
# ----------------------------------------------------------------------------
# System-behavior and per-application user defaults.
{config, ...}: {
  forge.userDefaults = {
    # --- [ACTIVITY_MONITOR]
    "com.apple.ActivityMonitor" = {
      ShowCategory = 100;
      IconType = 0;
      SortColumn = "CPUUsage";
      SortDirection = 0;
      OpenMainWindow = true;
    };
    # --- [SCREENSHOTS]
    "com.apple.screencapture" = {
      location = "${config.home.homeDirectory}/Downloads";
      type = "png";
      disable-shadow = true;
      include-date = true;
      show-thumbnail = false;
      target = "file";
      save-selections = true;
    };
    # --- [MENU_BAR_CLOCK]
    "com.apple.menuextra.clock" = {
      Show24Hour = true;
      ShowDate = 1;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
      ShowSeconds = false;
      FlashDateSeparators = false;
      IsAnalog = false;
    };
    # --- [ACCESSIBILITY]
    "com.apple.universalaccess" = {
      closeViewScrollWheelToggle = false;
      closeViewZoomFollowsFocus = false;
      reduceMotion = true; # a screenshot taken mid-animation misreads window geometry
      reduceTransparency = false;
      mouseDriverCursorSize = 1.0; # 1.0 is the floor; macOS clamps lower values up
    };
    # --- [GLOBAL_SYSTEM_BEHAVIOR]
    NSGlobalDomain = {
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.sound.beep.sound" = "/System/Library/Sounds/Tink.aiff";
    };
    "com.apple.iCal"."first day of week" = 0; # 0 = system setting
    # --- [APPLICATION_SPECIFIC_SETTINGS]
    # Screen-lock delay is sysadminctl/profile-owned since Big Sur (com.apple.screensaver askForPassword keys are decorative), and Siri/Apple
    # Intelligence disablement is Settings-owned on Tahoe — neither surface carries a truthful defaults row.
    "com.apple.Terminal".SecureKeyboardEntry = false;
    "com.apple.dt.Xcode".DVTTextEditorTrimTrailingWhitespace = true;
    "com.lujjjh.LinearMouse" = {
      showInDock = false; # menu-bar-only posture; the launchd agent owns startup
      menuBarBatteryDisplayMode = "\"below20\""; # MX battery surfaces at 20% — Codable string, embedded quotes required
      betaChannelOn = true; # Sparkle stays on the beta feed the installed release (the apps/linearmouse schema row's version) ships from
      autoSwitchToActiveDevice = true;
      # Sparkle: check and install in the background, send no system profile; unset, Sparkle asks on the second launch.
      SUEnableAutomaticChecks = true;
      SUAutomaticallyUpdate = true;
      SUSendProfileInfo = false;
    };
    # --- [ARCHIVES]
    # BetterZip: double-click extracts, the Finder toolbar button and contextual menu carry every preset, extracted apps keep their
    # quarantine flag, the stable Sparkle feed (a SUFeedURL row would select the beta feed), no menu-bar icon. Archive Types and the
    # Finder-extension mirror in the app group container are written by the app from these rows.
    "com.macitbetter.betterzip" = {
      SUEnableAutomaticChecks = true;
      MIBDirectExtractByDefault = true;
      MIBShowFinderButton = true;
      MIBShowFinderContextualMenu = true;
      MIBShowAdditionalFinderActions = true;
      MIBDontQuarantineApps = false;
      MIBPostNotifications = true;
      MIBMenubarItem = false;
    };
    # --- [QUICK_LOOK_APPS]
    # Each app registers its Quick Look extension on first launch; these rows keep the later launches silent.
    "org.sbarex.QLMarkdown" = {
      "qlmarkdown-suppress-editor-warning" = true; # the launch notice that the app is not a Markdown editor
      SUEnableAutomaticChecks = true;
      SUAutomaticallyUpdate = true;
      SUSendProfileInfo = false;
    };
    "org.sbarex.SourceCodeSyntaxHighlight" = {
      SUEnableAutomaticChecks = true;
      SUAutomaticallyUpdate = true;
      SUSendProfileInfo = false;
    };
    # Suspicious Package reaches a selected .pkg through its Finder service (macOS 13.3 dropped it from Open With); pbs holds the
    # Services Settings election the vendor FAQ names under the Development group.
    pbs.NSServicesStatus."com.mothersruin.SuspiciousPackageApp - Open With Suspicious Package - openSelectedPackage" = {
      enabled_context_menu = true;
      enabled_services_menu = true;
      presentation_modes = {
        ContextMenu = true;
        ServicesMenu = true;
      };
    };
  };
}
