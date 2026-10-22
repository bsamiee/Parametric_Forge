# Title         : system.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/defaults/system.nix
# ----------------------------------------------------------------------------
# System-behavior and per-application user defaults.
{config, ...}: {
  targets.darwin.defaults = {
    # --- [ACTIVITY_MONITOR]
    "com.apple.ActivityMonitor" = {
      ShowCategory = 100;
      IconType = 0;
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
      ShowDate = 1;
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
    # --- [SEARCH_SUGGESTIONS]
    # Spotlight pane rows as macOS 27 writes them: the Custom.relatedContents rule turns Show Related Content (Apple partner content in
    # Spotlight and Look Up) off, and sharing status 2 turns Help Apple Improve Search off. Safari's Search settings: no search engine
    # suggestions, no Safari Suggestions. Per-app Siri Suggestions learning is the suggestion-blocklist agent's (mac-tools/suggestions.nix).
    "com.apple.Spotlight".EnabledPreferenceRules = ["Custom.relatedContents"];
    "com.apple.assistant.support"."Search Queries Data Sharing Status" = 2;
    "com.apple.Safari" = {
      SuppressSearchSuggestions = true;
      UniversalSearchEnabled = false;
    };
    # --- [APPLICATION_SPECIFIC_SETTINGS]
    # Screen-lock delay is sysadminctl/profile-owned since Big Sur (com.apple.screensaver askForPassword keys are decorative). The Apple
    # Intelligence knowledge pipelines (spotlightknowledged embeddings) run independent of Siri and of the suggestion blocklist, and macOS 27
    # carries no unsupervised switch for them (the intelligence settings declaration needs a supervised Mac); Spotlight exclusions are the
    # scope lever.
    "com.apple.Terminal".SecureKeyboardEntry = false;
    "com.apple.dt.Xcode".DVTTextEditorTrimTrailingWhitespace = true;
    "com.lujjjh.LinearMouse" = {
      showInDock = false; # menu-bar-only posture; the launchd agent owns startup
      menuBarBatteryDisplayMode = "\"below20\""; # MX battery surfaces at 20% — Codable string, embedded quotes required
      betaChannelOn = true; # Sparkle stays on the beta feed the installed linearmouse@beta cask ships from
      autoSwitchToActiveDevice = true;
      # Sparkle: check and install in the background, send no system profile; unset, Sparkle asks on the second launch.
      SUEnableAutomaticChecks = true;
      SUAutomaticallyUpdate = true;
      SUSendProfileInfo = false;
    };
    # --- [ARCHIVES]
    # BetterZip: double-click extracts, the Finder toolbar button and contextual menu carry every preset, extracted apps carry no quarantine
    # flag, the stable Sparkle feed (a SUFeedURL row would select the beta feed), no menu-bar icon. Archive Types and the Finder-extension
    # mirror in the app group container are written by the app from these rows.
    "com.macitbetter.betterzip" = {
      SUEnableAutomaticChecks = true;
      MIBDirectExtractByDefault = true;
      MIBShowFinderButton = true;
      MIBShowFinderContextualMenu = true;
      MIBShowAdditionalFinderActions = true;
      MIBDontQuarantineApps = true;
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
    # Services Settings election the vendor FAQ names under the Development group. NSServicesStatus is owned whole: every Services election
    # is a row here, and the import replaces the key each switch.
    pbs.NSServicesStatus."com.mothersruin.SuspiciousPackageApp - Open With Suspicious Package - openSelectedPackage" = {
      enabled_context_menu = true;
      enabled_services_menu = true;
      presentation_modes = {
        ContextMenu = true;
        ServicesMenu = true;
      };
    };
  };

  # --- [AIRBUDDY]
  # One Mac: multi-Mac discovery (the _abm-mhp-v2 Bonjour browse over AWDL every 10 minutes) stays off. Proximity scanning is how the app
  # reads battery levels and has no off switch.
  forge.groupDefaults."8C7439RJLG.group.codes.rambo.AirBuddy".isMultiHostEnabled = false;
}
