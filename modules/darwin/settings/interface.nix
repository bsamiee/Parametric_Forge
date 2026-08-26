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
        autohide = mkDefault false;
        show-process-indicators = mkDefault true;
        show-recents = mkDefault false;
        static-only = mkDefault false;
        minimize-to-application = mkDefault true;
        mineffect = mkDefault "scale";
        launchanim = mkDefault false;
        showhidden = mkDefault false;
        expose-group-apps = mkDefault false;
        mru-spaces = mkDefault false;
        # Static, animation-minimal dock: instant autohide timing, fast Mission Control, stock gestures pinned. Launchpad died with Tahoe's
        # Spotlight apps view, so its gesture row never lands.
        appswitcher-all-displays = mkDefault false;
        autohide-delay = mkDefault 0.0;
        autohide-time-modifier = mkDefault 0.0;
        expose-animation-duration = mkDefault 0.1;
        scroll-to-open = mkDefault false;
        slow-motion-allowed = mkDefault false;
        mouse-over-hilite-stack = mkDefault false;
        showAppExposeGestureEnabled = mkDefault true;
        showMissionControlGestureEnabled = mkDefault true;
        showDesktopGestureEnabled = mkDefault true;
        # Hot corners disabled: corner action 1 is the no-op.
        wvous-tl-corner = mkDefault 1;
        wvous-tr-corner = mkDefault 1;
        wvous-bl-corner = mkDefault 1;
        wvous-br-corner = mkDefault 1;
        # Pin sources: Drafts is masApp-declared; Claude and ChatGPT are intentional manual installs.
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
          "/Applications/ChatGPT.app"
          "/Applications/Claude.app"
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
      # Control Center/menu-bar layout has no supported defaults surface on Tahoe (Edit Controls owns it); Ice manages menu-bar items and
      # AlDente owns battery presentation, so no controlcenter rows exist here.
      # --- [GLOBAL_SYSTEM_DEFAULTS]
      NSGlobalDomain = {
        AppleInterfaceStyle = mkDefault "Dark";
        AppleInterfaceStyleSwitchesAutomatically = mkDefault false;
        AppleIconAppearanceTheme = mkDefault "RegularDark"; # icon/widget dark style
        _HIHideMenuBar = mkDefault false; # menu bar stays visible
        AppleShowScrollBars = mkDefault "WhenScrolling";
        AppleScrollerPagingBehavior = mkDefault false;
        AppleICUForce24HourTime = mkDefault true;
        AppleTemperatureUnit = mkDefault "Fahrenheit";
        AppleMeasurementUnits = mkDefault "Inches";
        AppleMetricUnits = mkDefault 0;
        AppleFontSmoothing = mkDefault 0;
        # Menu-bar density: native is 16/16; 12/6 tightens one step without crowding. Ice's spacing slider writes the same keys into the
        # ByHost store, which shadows these rows — its offset stays zeroed so this declaration owns the surface.
        NSStatusItemSpacing = mkDefault 12;
        NSStatusItemSelectionPadding = mkDefault 6;
        NSTableViewDefaultSizeMode = mkDefault 1;
        AppleWindowTabbingMode = mkDefault "manual";
        NSNavPanelExpandedStateForSaveMode = mkDefault true;
        NSNavPanelExpandedStateForSaveMode2 = mkDefault true;
        PMPrintingExpandedStateForPrint = mkDefault true;
        PMPrintingExpandedStateForPrint2 = mkDefault true;
        NSDocumentSaveNewDocumentsToCloud = mkDefault false;
        NSWindowResizeTime = mkDefault 0.001; # instant window resize
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
        # Preferences only: serialized UI state (sidebar width/disclosure, info panes, NSToolbar dicts) is Finder-owned runtime state, never
        # declared — Tahoe guarantees no stable schema for it.
        "com.apple.finder" = {
          ShowRecentTags = mkDefault false;
          FavoriteTagNames = mkDefault [];
          ShowSidebar = mkDefault true;
          SidebarShowingiCloudDesktop = mkDefault false;
          SidebarShowingSignedIntoiCloud = mkDefault true;
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
