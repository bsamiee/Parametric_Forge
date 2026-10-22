# Title         : interface.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/mac-tools/defaults/interface.nix
# ----------------------------------------------------------------------------
# Visual interface and desktop environment defaults.
{config, ...}: let
  inherit (config.forge) apps;
in {
  targets.darwin.defaults = {
    # --- [DOCK_CONFIGURATION]
    "com.apple.dock" = {
      orientation = "bottom";
      tilesize = 28;
      largesize = 128;
      magnification = false;
      autohide = false;
      show-process-indicators = true;
      show-recents = false;
      static-only = false;
      minimize-to-application = true;
      mineffect = "scale";
      launchanim = false;
      showhidden = false;
      expose-group-apps = false;
      mru-spaces = false;
      # Static, animation-minimal dock: instant autohide timing, stock gestures pinned. Launchpad died with Tahoe's Spotlight apps view, so
      # its gesture row never lands.
      appswitcher-all-displays = false;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      scroll-to-open = false;
      slow-motion-allowed = false;
      mouse-over-hilite-stack = false;
      showAppExposeGestureEnabled = true;
      showMissionControlGestureEnabled = true;
      showDesktopGestureEnabled = true;
      # Hot corners disabled: corner action 1 is the no-op.
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
      no-bouncing = false;
      enable-spring-load-actions-on-all-items = true;
      # Pin sources: Drafts is masApp-declared; Claude, ChatGPT, and the Adobe suite (Creative Cloud installer-owned) are intentional manual installs.
      # Paths read from the application rows (mac-tools/default-applications.nix).
      persistent-apps = [{spacer = {};}] ++ map (name: apps.${name}.path) ["heptabase" "drafts" "vscode" "arc" "wezterm" "chatgpt" "claude" "superhuman" "messages" "creativeCloud" "indesign" "photoshop" "illustrator" "acrobat"];
      persistent-others = [];
    };
    # --- [FINDER_CONFIGURATION]
    # Preferences only: serialized UI state (sidebar width/disclosure, info panes, NSToolbar dicts) is Finder-owned runtime state, never
    # declared — Tahoe guarantees no stable schema for it.
    "com.apple.finder" = {
      CreateDesktop = true;
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = true;
      ShowRemovableMediaOnDesktop = true;
      FXDefaultSearchScope = "SCcf";
      FXPreferredViewStyle = "Nlsv";
      AppleShowAllExtensions = true;
      _FXSortFoldersFirst = true;
      NewWindowTarget = "PfLo"; # PfLo = the NewWindowTargetPath location
      NewWindowTargetPath = "file://${config.home.homeDirectory}/Downloads/";
      ShowPathbar = true; # Finder reads ShowPathbar; Home Manager's typed ShowPathBar is a key Finder never reads
      ShowStatusBar = false;
      _FXShowPosixPathInTitle = false;
      QuitMenuItem = false;
      FXEnableExtensionChangeWarning = false;
      FXRemoveOldTrashItems = true;
      _FXSortFoldersFirstOnDesktop = true;
      _FXEnableColumnAutoSizing = true;
      ShowRecentTags = false;
      FavoriteTagNames = [];
      ShowSidebar = true;
      SidebarShowingiCloudDesktop = false;
      SidebarShowingSignedIntoiCloud = true;
      FXArrangeGroupViewBy = "Name";
      FXPreferredGroupBy = "None";
    };
    # --- [WINDOW_MANAGEMENT]
    "com.apple.WindowManager" = {
      GloballyEnabled = false;
      EnableStandardClickToShowDesktop = false;
      AutoHide = false;
      AppWindowGroupingBehavior = true;
      HideDesktop = true;
      StandardHideDesktopIcons = false;
      StandardHideWidgets = false;
      StageManagerHideWidgets = false;
      EnableTilingByEdgeDrag = false;
      EnableTopTilingByEdgeDrag = false;
      EnableTilingOptionAccelerator = false;
      EnableTiledWindowMargins = false;
    };
    # --- [SPACES_CONFIGURATION]
    "com.apple.spaces".spans-displays = false;
    # Control Center/menu-bar layout has no supported defaults surface on Tahoe (Edit Controls owns it) and AlDente owns battery presentation,
    # so no controlcenter rows exist here.
    # --- [GLOBAL_SYSTEM_DEFAULTS]
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
      AppleIconAppearanceTheme = "RegularDark"; # icon/widget dark style
      _HIHideMenuBar = false; # menu bar stays visible
      AppleShowScrollBars = "WhenScrolling";
      AppleScrollerPagingBehavior = false;
      AppleICUForce24HourTime = true;
      AppleTemperatureUnit = "Fahrenheit";
      AppleMeasurementUnits = "Inches";
      AppleMetricUnits = false;
      AppleFontSmoothing = 0;
      # Menu-bar density: native is 16/16; 12/6 tightens one step without crowding.
      NSStatusItemSpacing = 12;
      NSStatusItemSelectionPadding = 6;
      NSTableViewDefaultSizeMode = 1;
      AppleWindowTabbingMode = "manual";
      NSNavPanelExpandedStateForSaveMode = true;
      PMPrintingExpandedStateForPrint = true;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSWindowResizeTime = 0.001; # instant window resize
      NSWindowShouldDragOnGesture = false;
      NSAutomaticWindowAnimationsEnabled = false;
      NSUseAnimatedFocusRing = false;
      NSScrollAnimationEnabled = true;
      AppleShowAllFiles = false;
      NSDisableAutomaticTermination = false;
      NSTextShowsControlCharacters = false;
      "com.apple.springing.enabled" = true;
      "com.apple.springing.delay" = 0.25;
      AppleSpacesSwitchOnActivate = false;
      AppleActionOnDoubleClick = "Maximize";
      AppleMiniaturizeOnDoubleClick = false;
      AppleMenuBarVisibleInFullscreen = true;
    };
  };
}
