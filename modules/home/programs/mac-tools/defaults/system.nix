{
  config,
  lib,
  pkgs,
  ...
}: {
  home.activation.setSyntaxHighlightDefaults = lib.hm.dag.entryAfter ["setDarwinDefaults"] ''
    run /usr/bin/defaults import ${lib.escapeShellArg "${config.home.homeDirectory}/Library/Preferences/org.sbarex.SourceCodeSyntaxHighlight"} ${pkgs.writeText "syntax-highlight-renderer.plist" (lib.generators.toPlist {escape = true;} {
      format = "html";
      "theme-dark" = "base16/dracula";
      "font-family" = config.forge.fonts.roles.${config.forge.fonts.surfaces.quicklook.family};
      "font-size" = config.forge.fonts.surfaces.quicklook.size;
      "word-wrap" = 2;
      "word-wrap-hard" = false;
      "line-numbers" = true;
      "line-fill-zero" = false;
      "indent-guides" = true;
      interactive = true;
      about = false;
    })}
  '';
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
      reduceMotion = true;
      reduceTransparency = false;
      mouseDriverCursorSize = 1.0;
    };
    # --- [GLOBAL_SYSTEM_BEHAVIOR]
    NSGlobalDomain = {
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.sound.beep.sound" = "/System/Library/Sounds/Tink.aiff";
    };
    "com.apple.iCal"."first day of week" = 0;
    # --- [SEARCH_SUGGESTIONS]
    "com.apple.Spotlight".EnabledPreferenceRules = ["Custom.relatedContents"];
    "com.apple.assistant.support"."Search Queries Data Sharing Status" = 2;
    "com.apple.Safari" = {
      SuppressSearchSuggestions = true;
      UniversalSearchEnabled = false;
    };
    # --- [APPLICATION_SPECIFIC_SETTINGS]
    "com.apple.Terminal".SecureKeyboardEntry = false;
    "com.apple.dt.Xcode".DVTTextEditorTrimTrailingWhitespace = true;
    "com.lujjjh.LinearMouse" = {
      showInDock = false;
      menuBarBatteryDisplayMode = "\"below20\"";
      betaChannelOn = true;
      autoSwitchToActiveDevice = true;
      SUEnableAutomaticChecks = true;
      SUAutomaticallyUpdate = true;
      SUSendProfileInfo = false;
    };
    # --- [ARCHIVES]
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
    "org.sbarex.QLMarkdown" = {
      "qlmarkdown-suppress-editor-warning" = true;
      SUEnableAutomaticChecks = true;
      SUAutomaticallyUpdate = true;
      SUSendProfileInfo = false;
    };
    "org.sbarex.SourceCodeSyntaxHighlight" = {
      SUEnableAutomaticChecks = true;
      SUAutomaticallyUpdate = true;
      SUSendProfileInfo = false;
    };
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
  forge.groupDefaults."8C7439RJLG.group.codes.rambo.AirBuddy".isMultiHostEnabled = false;
}
