# Title         : 00.system/darwin/settings/interface.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/settings/interface.nix
# ----------------------------------------------------------------------------
# Visual interface and desktop environment settings for Darwin.

{ lib, context, ... }:

let
  inherit (lib) mkDefault mkMerge;
in
{
  system.defaults = mkMerge [
    {
      # --- Dock Configuration -----------------------------------------------
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
        # Application management
        persistent-apps = mkDefault [
          "/System/Applications/iPhone Mirroring.app"
          {
            spacer = {
              small = false;
            };
          }
          "/Applications/Heptabase.app"
          "/Applications/Drafts.app"
          "/Applications/Visual Studio Code.app"
          "/Applications/Kiro.app"
          "/Applications/Arc.app"
          "/Applications/WezTerm.app"
          "/Applications/Superhuman.app"
          "/System/Applications/Messages.app"
        ];
        persistent-others = mkDefault [ ];
      };
      # --- Finder Configuration ---------------------------------------------
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
        NewWindowTargetPath = mkDefault "file://${context.userHome}/Downloads/";
        ShowPathbar = mkDefault true;
        ShowStatusBar = mkDefault false;
        _FXShowPosixPathInTitle = mkDefault false;
        QuitMenuItem = mkDefault false;
        FXEnableExtensionChangeWarning = mkDefault false;
      };
      # --- Window Management ------------------------------------------------
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
      # --- Spaces Configuration ---------------------------------------------
      spaces = {
        spans-displays = mkDefault false;
      };
      # --- Global System Defaults -------------------------------------------
      NSGlobalDomain = {
        AppleInterfaceStyle = mkDefault "Dark";
        AppleInterfaceStyleSwitchesAutomatically = mkDefault false;
        AppleShowScrollBars = mkDefault "WhenScrolling";
        AppleScrollerPagingBehavior = mkDefault false;
        AppleFontSmoothing = mkDefault 0;
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
        AppleShowAllExtensions = mkDefault true;
        AppleShowAllFiles = mkDefault false;
        NSDisableAutomaticTermination = mkDefault false;
        NSTextShowsControlCharacters = mkDefault false;
        "com.apple.springing.enabled" = mkDefault true;
        "com.apple.springing.delay" = mkDefault 0.25;
        AppleSpacesSwitchOnActivate = mkDefault false;
      };
    }
    # --- Advanced Interface Customizations ----------------------------------
    {
      CustomUserPreferences = {
        # --- NSGlobalDomain Interface Settings ------------------------------
        NSGlobalDomain = {
          AppleActionOnDoubleClick = mkDefault "Maximize";
          AppleMiniaturizeOnDoubleClick = mkDefault false;
          AppleMenuBarVisibleInFullscreen = mkDefault true;
        };
        # --- Finder Advanced Settings ---------------------------------------
        "com.apple.finder" = {
          ShowRecentTags = mkDefault false;
          FavoriteTagNames = mkDefault [ ];
          ShowSidebar = mkDefault true;
          SidebarWidth = mkDefault 189;
          SidebarDevicesSectionDisclosedState = mkDefault true;
          SidebarPlacesSectionDisclosedState = mkDefault true;
          SidebarShowingiCloudDesktop = mkDefault false;
          SidebarShowingSignedIntoiCloud = mkDefault true;
          SidebarTagsSctionDisclosedState = mkDefault false;
          QLEnableTextSelection = mkDefault true;
          FXRemoveOldTrashItems = mkDefault true;
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
          "NSWindowTabbingShoudShowTabBarKey-com.apple.finder.TBrowserWindow" = mkDefault false;
          FXArrangeGroupViewBy = mkDefault "Name";
          FXPreferredGroupBy = mkDefault "None";
        };
        "com.apple.finder.qlcache" = {
          enableTextSelection = mkDefault true;
        };
        # --- Dock Hidden Settings -------------------------------------------
        "com.apple.dock" = {
          "no-bouncing" = mkDefault false;
          "enable-spring-load-actions-on-all-items" = mkDefault true;
        };
        # --- Menu Bar Spacing (tighter menu bar) ----------------------------
        "-globalDomain" = {
          NSStatusItemSpacing = mkDefault 6;
          NSStatusItemSelectionPadding = mkDefault 3;
        };
      };
    }
  ];
}
