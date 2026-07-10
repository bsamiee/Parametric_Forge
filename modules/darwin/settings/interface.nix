# Title         : interface.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/settings/interface.nix
# ----------------------------------------------------------------------------
# Visual interface and desktop environment settings for Darwin.
{
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault mkMerge;
in {
  system.defaults = mkMerge [
    {
      # --- [DOCK_CONFIGURATION]
      dock = {
        orientation = mkDefault "bottom";
        tilesize = mkDefault 28;
        largesize = mkDefault 128;
        magnification = mkDefault false;
        autohide = mkDefault false; # Keep Dock visible
        show-process-indicators = mkDefault true;
        show-recents = mkDefault false;
        static-only = mkDefault false;
        minimize-to-application = mkDefault true;
        mineffect = mkDefault "scale";
        launchanim = mkDefault false;
        showhidden = mkDefault false;
        expose-group-apps = mkDefault false;
        mru-spaces = mkDefault false;
        # Hot corners - all disabled
        wvous-tl-corner = mkDefault 1;
        wvous-tr-corner = mkDefault 1;
        wvous-bl-corner = mkDefault 1;
        wvous-br-corner = mkDefault 1;
        # Pin sources: Drafts is masApp-declared; Claude/Codex are intentional
        # manual installs pinned by operator ruling.
        persistent-apps = mkDefault [
          {
            spacer = {
              small = false;
            };
          }
          "/Applications/Heptabase.app"
          "/Applications/Drafts.app"
          "/Applications/Visual Studio Code.app"
          "/Applications/Arc.app"
          "/Applications/WezTerm.app"
          "/Applications/Claude.app"
          "/Applications/ChatGPT.app"
          "/Applications/Superhuman.app"
          "/System/Applications/Messages.app"
        ];
        persistent-others = mkDefault [];
      };
      # --- [FINDER_CONFIGURATION]
      finder = {
        CreateDesktop = mkDefault true;
        ShowExternalHardDrivesOnDesktop = mkDefault true;
        ShowHardDrivesOnDesktop = mkDefault false;
        ShowMountedServersOnDesktop = mkDefault true;
        ShowRemovableMediaOnDesktop = mkDefault true;
        FXDefaultSearchScope = mkDefault "SCcf";
        FXPreferredViewStyle = mkDefault "Nlsv";
        AppleShowAllExtensions = mkDefault true;
        _FXSortFoldersFirst = mkDefault true;
        NewWindowTarget = mkDefault "Other";
        NewWindowTargetPath = mkDefault "file://${config.users.users.${config.system.primaryUser}.home}/Downloads/";
        ShowPathbar = mkDefault true;
        ShowStatusBar = mkDefault false;
        _FXShowPosixPathInTitle = mkDefault false;
        QuitMenuItem = mkDefault false;
        FXEnableExtensionChangeWarning = mkDefault false;
        FXRemoveOldTrashItems = mkDefault true;
        _FXSortFoldersFirstOnDesktop = mkDefault true;
        _FXEnableColumnAutoSizing = mkDefault true;
      };
      # --- [WINDOW_MANAGEMENT]
      WindowManager = {
        GloballyEnabled = mkDefault false;
        EnableStandardClickToShowDesktop = mkDefault false;
        AutoHide = mkDefault false;
        AppWindowGroupingBehavior = mkDefault true;
        HideDesktop = mkDefault true;
        StandardHideDesktopIcons = mkDefault false;
        StandardHideWidgets = mkDefault false;
        StageManagerHideWidgets = mkDefault false;
        EnableTilingByEdgeDrag = mkDefault false;
        EnableTopTilingByEdgeDrag = mkDefault false;
        EnableTilingOptionAccelerator = mkDefault false;
        EnableTiledWindowMargins = mkDefault false;
      };
      # --- [SPACES_CONFIGURATION]
      spaces = {
        spans-displays = mkDefault false;
      };
      # --- [CONTROL_CENTER_MENU_BAR_BYHOST_DOMAIN]
      # Minimal menu-bar posture: every optional module hidden, battery
      # percentage flag kept true for the Control Center pane readout.
      controlcenter = {
        AirDrop = mkDefault false;
        BatteryShowPercentage = mkDefault true;
        Bluetooth = mkDefault false;
        Display = mkDefault false;
        FocusModes = mkDefault false;
        NowPlaying = mkDefault false;
        Sound = mkDefault false;
      };
      # --- [GLOBAL_SYSTEM_DEFAULTS]
      NSGlobalDomain = {
        AppleInterfaceStyle = mkDefault "Dark";
        AppleInterfaceStyleSwitchesAutomatically = mkDefault false;
        AppleIconAppearanceTheme = mkDefault "RegularDark"; # Tahoe icon/widget dark style
        _HIHideMenuBar = mkDefault false; # Pin menu bar visible under Tahoe
        AppleShowScrollBars = mkDefault "WhenScrolling";
        AppleScrollerPagingBehavior = mkDefault false;
        AppleICUForce24HourTime = mkDefault true;
        NSTableViewDefaultSizeMode = mkDefault 1;
        AppleWindowTabbingMode = mkDefault "manual";
        NSNavPanelExpandedStateForSaveMode = mkDefault true;
        NSNavPanelExpandedStateForSaveMode2 = mkDefault true;
        NSDocumentSaveNewDocumentsToCloud = mkDefault false;
        NSWindowResizeTime = mkDefault 0.001; # PERFORMANCE: Instant window resize
        NSWindowShouldDragOnGesture = mkDefault false;
        NSAutomaticWindowAnimationsEnabled = mkDefault false;
        NSUseAnimatedFocusRing = mkDefault false;
        NSScrollAnimationEnabled = mkDefault true;
        AppleShowAllFiles = mkDefault false;
        NSDisableAutomaticTermination = mkDefault false;
        NSTextShowsControlCharacters = mkDefault false;
        "com.apple.springing.enabled" = mkDefault true;
        "com.apple.springing.delay" = mkDefault 0.25;
        AppleSpacesSwitchOnActivate = mkDefault false;
      };
    }
    # --- [ADVANCED_INTERFACE_CUSTOMIZATIONS]
    {
      CustomUserPreferences = {
        # --- [NSGLOBALDOMAIN_INTERFACE_SETTINGS]
        NSGlobalDomain = {
          AppleActionOnDoubleClick = mkDefault "Maximize";
          AppleMiniaturizeOnDoubleClick = mkDefault false;
          AppleMenuBarVisibleInFullscreen = mkDefault true;
        };
        # --- [FINDER_ADVANCED_SETTINGS]
        "com.apple.finder" = {
          ShowRecentTags = mkDefault false;
          FavoriteTagNames = mkDefault [];
          ShowSidebar = mkDefault true;
          SidebarWidth = mkDefault 189;
          SidebarDevicesSectionDisclosedState = mkDefault true;
          SidebarPlacesSectionDisclosedState = mkDefault true;
          SidebarShowingiCloudDesktop = mkDefault false;
          SidebarShowingSignedIntoiCloud = mkDefault true;
          FXInfoPanesExpanded = {
            General = mkDefault true;
            OpenWith = mkDefault true;
            Privileges = mkDefault true;
          };
          "NSToolbar Configuration Browser" = {
            "TB Display Mode" = mkDefault 2;
            "TB Icon Size Mode" = mkDefault 1;
            "TB Is Shown" = mkDefault 1;
            "TB Size Mode" = mkDefault 1;
            "TB Item Identifiers" = mkDefault [
              "com.apple.finder.BACK"
              "com.apple.finder.SWCH"
              "com.apple.finder.NFLD"
              "NSToolbarFlexibleSpaceItem"
              "com.apple.finder.INFO"
              "com.apple.finder.AirD"
              "com.apple.finder.SHAR"
              "NSToolbarSpaceItem"
              "com.apple.finder.SRCH"
            ];
          };
          FXArrangeGroupViewBy = mkDefault "Name";
          FXPreferredGroupBy = mkDefault "None";
        };
        # --- [DOCK_HIDDEN_SETTINGS]
        "com.apple.dock" = {
          "no-bouncing" = mkDefault false;
          "enable-spring-load-actions-on-all-items" = mkDefault true;
        };
      };
    }
  ];
}
