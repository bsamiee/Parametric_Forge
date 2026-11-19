{
  applications,
  config,
  lib,
  pkgs,
  typography,
  ...
}: let
  home = config.home.homeDirectory;
  preferences = "${home}/Library/Preferences";
  support = "${home}/Library/Application Support";
  sd = lib.getExe pkgs.sd;
  dvaDebugRows = {
    "After Effects (Beta)" = {
      "dvaappsupport.feature.AE.MCPServer" = ["1" ""];
      "dvaappsupport.feature.AE.UXPPlugins" = ["1" ""];
      "FE.TestBetaMenu" = ["true" "false"];
    };
    "Premiere Pro (Beta)" = {
      "dvaappsupport.feature.PPro.MCP.EnableMCPServer" = ["1" ""];
      "FE.TestBetaMenu" = ["true" "false"];
      "ThirdPartyUseStage" = ["true" "false"];
      "UIF.ForceEnableDebugMenu" = ["true" "false"];
    };
    "Adobe Media Encoder (Beta)" = {
      "dvaappsupport.feature.AME.MCP.EnableMCPServer" = ["1" ""];
      "FE.TestBetaMenu" = ["true" "false"];
      "UIF.ForceEnableDebugMenu" = ["true" "false"];
    };
  };
  jsonMerge = file: keys: ''
    run ${pkgs.runtimeShell} -c ${lib.escapeShellArg ''
      set -eu
      f=${lib.escapeShellArg file}
      ${pkgs.coreutils}/bin/mkdir -p "''${f%/*}"
      { [ -s "$f" ] && ${pkgs.gnugrep}/bin/grep -v '^[[:space:]]*//' "$f" || printf '{}'; } \
        | ${lib.getExe pkgs.jq} ${lib.escapeShellArg ". + ${builtins.toJSON keys}"} >"$f.tmp"
      if ${pkgs.diffutils}/bin/cmp -s "$f.tmp" "$f"; then ${pkgs.coreutils}/bin/rm "$f.tmp"; else ${pkgs.coreutils}/bin/mv "$f.tmp" "$f"; fi
    ''}
  '';
in {
  home.file =
    lib.genAttrs' ["Adobe Photoshop 2027" "Adobe Photoshop (Beta)"] (channel:
      lib.nameValuePair "Library/Preferences/${channel} Settings/PSUserConfig.txt" {
        text = "WarnRunningScripts 0\nWarnDeepLinkPluginContact 0\n";
        force = true;
      })
    // {
      ".rive/analytics" = {
        text = "off\n";
        force = true;
      };
    };
  home.activation = {
    setElectronDevTools = lib.hm.dag.entryAfter ["writeBoundary"] (
      jsonMerge "${home}/.vscode/argv.json" {"remote-debugging-port" = "9223";}
      + jsonMerge "${support}/Claude/developer_settings.json" {allowDevTools = true;}
      + jsonMerge "${support}/discord/settings.json" {DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;}
    );
    setCreativeDeveloperPrefs = lib.hm.dag.entryAfter ["setDarwinDefaults"] ''
      if /usr/bin/pgrep -qf '\.app/Contents/MacOS/After Effects'; then
        noteEcho "After Effects is running: its scripting preferences wait for the next switch"
      else
        for f in ${lib.escapeShellArg "${preferences}/Adobe"}/After\ Effects*/*/Adobe\ After\ Effects\ *\ Prefs.txt; do
          [ -f "$f" ] || continue
          if /usr/bin/grep -qF '"Pref_SCRIPTING_FILE_NETWORK_SECURITY" = "0"' "$f"; then
            run ${sd} -F '"Pref_SCRIPTING_FILE_NETWORK_SECURITY" = "0"' '"Pref_SCRIPTING_FILE_NETWORK_SECURITY" = "1"' "$f"
          fi
          if ! /usr/bin/grep -qF '"Pref_WARN_WHEN_RUNNING_SCRIPTS"' "$f"; then
            run ${sd} -F "[\"Main Pref Section v2\"]"$'\r' "[\"Main Pref Section v2\"]"$'\r\t"Pref_WARN_WHEN_RUNNING_SCRIPTS" = 00\r' "$f"
          elif /usr/bin/grep -qF '"Pref_WARN_WHEN_RUNNING_SCRIPTS" = 01' "$f"; then
            run ${sd} -F '"Pref_WARN_WHEN_RUNNING_SCRIPTS" = 01' '"Pref_WARN_WHEN_RUNNING_SCRIPTS" = 00' "$f"
          fi
        done
      fi
      if /usr/bin/pgrep -qf '\.app/Contents/MacOS/(After Effects|Adobe Premiere Pro|Adobe Media Encoder) \(Beta\)'; then
        noteEcho "A DVA beta app is running: its Debug Database rows and Premiere MCP preferences wait for the next switch"
      else
        ${lib.concatStrings (lib.mapAttrsToList (app: rows: ''
          for f in ${lib.escapeShellArg "${preferences}/Adobe/${app}"}/*/Debug\ Database.txt; do
            [ -f "$f" ] || continue
            ${lib.concatStrings (lib.mapAttrsToList (key: values: let
              row = lib.escapeShellArg (lib.concatStringsSep "\t" ([key] ++ values));
            in ''
              if ! /usr/bin/grep -qxF ${row} "$f"; then
                run ${sd} -A ${lib.escapeShellArg "(?m)^${lib.escapeRegex key}\\t[^\\n]*\\n"} "" "$f"
                [ -n "''${DRY_RUN:-}" ] || printf '%s\n' ${row} >> "$f"
              fi
            '')
            rows)}
          done
        '')
        dvaDebugRows)}
        for f in ${lib.escapeShellArg "${home}/Documents/Adobe"}/Premiere\ Pro\ \(Beta\)/*/Profile-*/Adobe\ Premiere\ Pro\ \(Beta\)\ Prefs; do
          [ -f "$f" ] || continue
          if /usr/bin/grep -qF '<HSL.Prefs.McpEnabled>false<' "$f"; then
            run ${sd} -F '<HSL.Prefs.McpEnabled>false<' '<HSL.Prefs.McpEnabled>true<' "$f"
          fi
          if /usr/bin/grep -qF '<HSL.Prefs.McpAuthenticationEnabled>1<' "$f"; then
            run ${sd} -F '<HSL.Prefs.McpAuthenticationEnabled>1<' '<HSL.Prefs.McpAuthenticationEnabled>0<' "$f"
          fi
        done
      fi
      if /usr/bin/pgrep -qf 'Adobe Illustrator\.app/Contents/MacOS/Adobe Illustrator'; then
        noteEcho "Illustrator is running: AllowVSCodeDebuggerConnections waits for the next switch"
      else
        for f in ${lib.escapeShellArg preferences}/Adobe\ Illustrator\ */*/Adobe\ Illustrator\ Prefs; do
          [ -f "$f" ] || continue
          if /usr/bin/grep -qF '/AllowVSCodeDebuggerConnections 0' "$f"; then
            run ${sd} -F '/AllowVSCodeDebuggerConnections 0' '/AllowVSCodeDebuggerConnections 1' "$f"
          fi
        done
      fi
      if /usr/bin/pgrep -qx AdobeAcrobat; then
        noteEcho "Acrobat is running: JSPrefs waits for the next switch"
      else
        acrobat=$(mktemp)
        /usr/bin/defaults export com.adobe.Acrobat.Pro "$acrobat"
        keys="EnableDebugger ConsoleOpen ConsoleInput EnableMenuItems"
        if /usr/bin/plutil -type DC "$acrobat" >/dev/null 2>&1 \
          && ! /usr/bin/plutil -extract DC.JSPrefs json -o - "$acrobat" 2>/dev/null | ${lib.getExe pkgs.jq} -e --arg keys "$keys" '[.[$keys | splits(" ")]] | all(. == [0, true])' >/dev/null; then
          /usr/bin/plutil -type DC.JSPrefs "$acrobat" >/dev/null 2>&1 || /usr/bin/plutil -insert DC.JSPrefs -dictionary "$acrobat"
          for key in $keys; do
            /usr/bin/plutil -replace "DC.JSPrefs.$key" -json '[0,true]' "$acrobat"
          done
          run /usr/bin/defaults import com.adobe.Acrobat.Pro "$acrobat"
        fi
        rm -f "$acrobat"
      fi
      xcu=${lib.escapeShellArg "${support}/LibreOffice/4/user/registrymodifications.xcu"}
      if /usr/bin/pgrep -qx soffice; then
        noteEcho "LibreOffice is running: macro security and experimental mode wait for the next switch"
      elif [ -f "$xcu" ]; then
        updated="$(mktemp)"
        /bin/cp "$xcu" "$updated"
        ${sd} -A '<item oor:path="/org.openoffice.Office.Common/(?:Security/Scripting|Misc)"><prop oor:name="(?:MacroSecurityLevel|MacroRecorderMode|ExperimentalMode)"[^\n]*\n' "" "$updated"
        ${sd} -F '</oor:items>' '<item oor:path="/org.openoffice.Office.Common/Security/Scripting"><prop oor:name="MacroSecurityLevel" oor:op="fuse"><value>0</value></prop></item>
      <item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="MacroRecorderMode" oor:op="fuse"><value>true</value></prop></item>
      <item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="ExperimentalMode" oor:op="fuse"><value>true</value></prop></item>
      </oor:items>' "$updated"
        /usr/bin/cmp -s "$updated" "$xcu" || run /bin/cp "$updated" "$xcu"
        rm -f "$updated"
      fi
    '';
    setParallelsServer = lib.hm.dag.entryAfter ["writeBoundary"] ''
      prlsrvctl="/Applications/Parallels Desktop.app/Contents/MacOS/prlsrvctl"
      if server=$("$prlsrvctl" info --json 2>/dev/null) && user=$("$prlsrvctl" user list --json 2>/dev/null); then
        vmHome=${lib.escapeShellArg "${home}/Parallels"}
        [ "$(${lib.getExe pkgs.jq} -r '.[0].DEF_VM_HOME' <<<"$user")" = "$vmHome" ] || run "$prlsrvctl" user set --def-vm-home "$vmHome"
        [ "$(${lib.getExe pkgs.jq} -r '."Verbose log"' <<<"$server")" = on ] || run "$prlsrvctl" set --verbose-log on
        [ "$(${lib.getExe pkgs.jq} -r '."CEP mechanism"' <<<"$server")" = off ] || run "$prlsrvctl" set --cep off
      fi
    '';
  };
  targets.darwin.defaults = {
    # --- [ACTIVITY_MONITOR]
    "com.apple.ActivityMonitor" = {
      ShowCategory = 100;
      IconType = 0;
      OpenMainWindow = true;
    };
    # --- [SCREENSHOTS]
    "com.apple.screencapture" = {
      location = "${home}/Downloads";
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
      WebKitDebugDeveloperExtrasEnabled = true;
      WebKitDeveloperExtras = true;
    };
    "com.apple.iCal"."first day of week" = 0;
    # --- [SEARCH_SUGGESTIONS]
    "com.apple.Spotlight".EnabledPreferenceRules = ["Custom.relatedContents"];
    "com.apple.assistant.support"."Search Queries Data Sharing Status" = 2;
    "com.apple.suggestions".SiriCanLearnFromAppBlacklist = ["com.apple.python3" "com.apple.MobileSMS"];
    "com.apple.SocialLayer".SharedWithYouEnabled = false;
    "com.apple.Safari" = {
      SuppressSearchSuggestions = true;
      UniversalSearchEnabled = false;
      AllowRemoteAutomation = true;
      IncludeDevelopMenu = true;
    };
    # --- [APPLICATION_SPECIFIC_SETTINGS]
    "com.apple.Terminal".SecureKeyboardEntry = false;
    "com.apple.dt.Xcode" = {
      DVTTextEditorTrimTrailingWhitespace = true;
      ShowBuildOperationDuration = true;
      IDEBuildingContinueBuildingAfterErrors = true;
      IDESkipMacroFingerprintValidation = true;
      IDESkipPackagePluginFingerprintValidatation = true;
    };
    "com.apple.CrashReporter" = {
      DialogType = "none";
      UseUNC = true;
    };
    "com.microsoft.Word".OfficeWebAddinDeveloperExtras = true;
    "com.microsoft.Excel".OfficeWebAddinDeveloperExtras = true;
    "com.google.Chrome" = {
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      NSUserKeyEquivalents = {
        "Add Tab to New Split View" = "^$=";
        "Bookmark All Tabs…" = "@~$d";
        "Bookmark This Tab…" = "@$d";
        "Close Other Tabs" = "@$k";
        "New Tab" = "@~t";
        "Save Page As…" = "@~$s";
      };
      PasswordManagerEnabled = false;
      ShowFullUrlsInAddressBar = true;
    };
    "${home}/Library/Group Containers/8C7439RJLG.group.codes.rambo.AirBuddy/Library/Preferences/8C7439RJLG.group.codes.rambo.AirBuddy".isMultiHostEnabled = false;
    ${applications.tailscale.id}.TailscaleStartOnLogin = true;
    "com.lujjjh.LinearMouse" = {
      showInDock = false;
      menuBarBatteryDisplayMode = "\"below20\"";
      betaChannelOn = true;
      autoSwitchToActiveDevice = true;
      SUEnableAutomaticChecks = true;
      SUAutomaticallyUpdate = true;
      SUSendProfileInfo = false;
    };
    # --- [ADOBE_CEP]
    "com.adobe.CSXS.12" = {
      PlayerDebugMode = "1";
      LogLevel = "6";
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
    "${preferences}/org.sbarex.SourceCodeSyntaxHighlight" = {
      format = "html";
      "theme-dark" = "base16/dracula";
      "font-family" = typography.roles.${typography.surfaces.quicklook.family};
      "font-size" = typography.surfaces.quicklook.size;
      "word-wrap" = 2;
      "word-wrap-hard" = false;
      "line-numbers" = true;
      "line-fill-zero" = false;
      "indent-guides" = true;
      interactive = true;
      about = false;
    };
    # --- [VIRTUALIZATION]
    "com.parallels.Parallels Desktop" = {
      "Application preferences.Check for updates" = 2;
      "Application preferences.Download updates automatically" = 1;
      "ProductPromo.ForcePromoOff" = 1;
      "WelcomeScreenPromo.PromoOff" = 1;
    };
    # --- [AGENT_HOSTS]
    "com.github.wez.wezterm".NSAppSleepDisabled = true;
    "com.openai.codex".NSAppSleepDisabled = true;
    "com.anthropic.claudefordesktop".NSAppSleepDisabled = true;
    "com.microsoft.VSCode".NSAppSleepDisabled = true;
    # --- [BATTERY_SLEEP_FLOOR]
    "com.apphousekitchen.aldente-pro" = {
      completelyDisableSleep = 1;
      manualSleepReenableBatteryPercent = 20;
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

  # --- [AIRPLAY_RECEIVER]
  targets.darwin.currentHostDefaults."com.apple.controlcenter".AirplayReceiverEnabled = false;
}
