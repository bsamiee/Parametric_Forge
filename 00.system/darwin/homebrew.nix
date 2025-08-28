# Title         : 00.system/darwin/homebrew.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/homebrew.nix
# ----------------------------------------------------------------------------
# Homebrew and Mac App Store integration via nix-homebrew.

{ lib, context, ... }:

let
  inherit (lib) mkDefault;
in
{
  # --- Homebrew Integration -------------------------------------------------
  homebrew = {
    enable = mkDefault true;

    # --- Global Settings ----------------------------------------------------
    global = {
      autoUpdate = mkDefault false;
      brewfile = mkDefault true; # Enable Brewfile management
      # lockfiles defaults to false when brewfile is true (prevents Nix store write attempts)
    };
    # --- Activation Behavior ------------------------------------------------
    onActivation = {
      autoUpdate = mkDefault false;
      cleanup = mkDefault "zap"; # Remove all unmanaged packages
      upgrade = mkDefault false;
      extraFlags = mkDefault ["--verbose"]; # Better debugging output
    };
    # --- Essential Taps -----------------------------------------------------
    taps = [
      "homebrew/bundle" # Required for brewfile support
    ];
    # --- GUI Applications (Casks) -------------------------------------------
    casks = [
      # System & Core Tools
      "1password" # Password manager with macOS integration
      "cleanshot" # Advanced screenshot and screen recording tool
      "docker" # Docker Desktop containerization
      "dotnet-sdk" # .NET SDK (large, GUI tools)
      "wezterm@nightly" # Terminal emulator (nightly build)

      # Productivity & Window Management
      "airbuddy" # AirPods battery/connection manager
      "aldente" # Battery charge limiter for MacBooks
      "almighty" # System settings enhancer
      "alt-tab" # Windows-style alt-tab window switcher
      "bartender" # Menu bar organization
      "bettermouse" # Mouse customization tool
      "bettertouchtool" # Advanced input device customization
      "hazel" # Automated file organization
      "latest" # App update tracker
      "raycast" # Productivity launcher (Spotlight replacement)
      "superkey" # Keyboard enhancement tool
      "swish" # Window management via trackpad gestures
      "transnomino" # File renaming utility

      # Browsers & Internet
      "arc" # Modern web browser
      "firefox" # Mozilla Firefox browser
      "google-chrome" # Google Chrome browser
      "tor-browser" # Privacy-focused browser

      # Communication & Social
      "discord" # Discord chat platform
      "microsoft-teams" # Microsoft Teams collaboration
      "superhuman" # Premium email client
      "telegram" # Telegram messenger
      "zoom" # Zoom video conferencing

      # Cloud & Storage
      "google-drive" # Google Drive sync client
      "megasync" # MEGA cloud sync client
      "transmission" # BitTorrent client

      # Development & Design
      "heptabase" # Note-taking/knowledge base
      "iconjar" # Icon management tool
      "kiro" # Your Kiro app
      "replacicon" # App icon customization
      "rhino" # Rhino 8 CAD software
      "typeface3" # Font management
      "via" # Keyboard configuration
      "visual-studio-code" # VS Code editor

      # Media & Creative
      "blender" # 3D creation suite
      "calibre" # E-book management
      "lockdown-browser" # Respondus LockDown Browser
      "scrivener" # Writing software
      "spotify" # Spotify music streaming
      "steam" # Steam gaming platform

      # QuickLook Plugins
      "syntax-highlight" # Code syntax highlighting for 150+ file types
      "qlmarkdown" # Markdown preview with GitHub-flavored rendering
      "quicklook-json" # JSON formatted preview
      "quicklook-csv" # CSV/TSV table preview
      "betterzip" # Preview ZIP/TAR contents without extracting
      "suspicious-package" # Inspect macOS .pkg installers

      # Adobe & Creative Suite
      "adobe-acrobat-pro" # Adobe Acrobat DC
      "adobe-creative-cloud" # Adobe Creative Cloud manager
      "colorchecker-camera-calibration" # X-Rite color profiling tool
      "topaz-gigapixel-ai" # AI image upscaling
      "topaz-photo-ai" # AI photo enhancement
      "zxpinstaller" # Adobe extension installer

      # Utilities & System Enhancement
      "grammarly-desktop" # Grammarly writing assistant
      "parallels" # Parallels Desktop virtualization
      "rize" # Time tracking application
    ];

    # --- Installation Sources Summary ---------------------------------------
    #
    # ✓ Via Homebrew Casks (above): All major applications managed declaratively
    # ✓ Via Mac App Store (masApps): System-integrated apps with automatic updates
    # ✓ Via Nix Derivations (00.system/darwin/applications.nix): Custom apps unavailable in Homebrew
    #
    # --- Manual Installation Required ---------------------------------------
    # The following applications require manual download and installation:
    #
    # Adobe Plugin Managers:
    # ✓ aescripts + aeplugins: After Effects plugin manager (via system-level Nix derivation)
    # ✓ Astute Manager: Illustrator plugin manager (via system-level Nix derivation)
    # ✓ DNG Profile Manager: X-Rite ColorChecker calibration (via colorchecker-camera-calibration cask)
    #
    # Hardware-Specific:
    # - CZUR Scanner: Document scanner software (hardware-specific)
    #
    # Google Workspace (if standalone versions exist):
    # - Google Docs: Word processing (standalone app, not web)
    # - Google Sheets: Spreadsheet (standalone app, not web)
    # - Google Slides: Presentations (standalone app, not web)
    #
    # Reading & E-books:
    # - Readwise iBooks: iBooks integration tool
    # - Z-Library: E-book reader/manager (not in official repositories)
    #
    # Discontinued/Unidentified:
    # - Supercharge: Could not identify - may be discontinued or renamed

    # --- CLI Tools (Brews) --------------------------------------------------
    brews = [
      "codex" # AI coding assistant (ChatGPT CLI)
      "mono" # .NET runtime (dependency for some tools)
    ];
    # --- Mac App Store Applications -----------------------------------------
    masApps = {
      # Apple Ecosystem
      "Keynote" = 409183694;
      
      # Microsoft Suite
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Word" = 462054704;
      "OneDrive" = 823766827;
      
      # Productivity & Time Management
      "Drafts" = 1435957248;
      "Fantastical" = 975937182;
      "Goodnotes" = 1444383602;
      "Timery" = 1425368544;
      "Toggl Track" = 1291898086;
      
      # Communication & Social
      "WhatsApp" = 310633997;
      
      # Utilities & System
      "CARROTweather" = 993487541;
      "CleanMyMac" = 1339170533;
      "Icon Tool for Developers" = 554660130;
      "Keka" = 470158793;
      "Parcel" = 639968404;
      "Rapidmg" = 6451349778;
      
      # Reading & Media
      "Kindle" = 302584613;
      
      # Privacy & Security
      "MEGAVPN" = 6456784858;
    };
    # --- Whalebrew (Docker-based tools) -------------------------------------
    # whalebrews = [ ];

    # --- Cask Configuration -------------------------------------------------
    caskArgs = mkDefault {
      appdir = "/Applications";
      require_sha = true; # Security: verify checksums
      no_quarantine = true; # Performance: skip Gatekeeper (safe with SHA verification)
      no_binaries = false; # Allow cask binaries in PATH
      fontdir = "~/Library/Fonts"; # Font installation directory
      colorpickerdir = "~/Library/ColorPickers"; # ColorPicker plugin directory
      prefpanedir = "~/Library/PreferencePanes"; # PreferencePane plugin directory
      qlplugindir = "~/Library/QuickLook"; # QuickLook plugin directory
    };
  };
  # --- Nix-Homebrew Bridge Integration --------------------------------------
  nix-homebrew = {
    enable = mkDefault true;
    enableRosetta = mkDefault context.isAarch64; # Enable Rosetta for Apple Silicon Macs (x86_64 compatibility)
    inherit (context) user;
    autoMigrate = mkDefault true;
    # mutableTaps = mkDefault false; # REMOVED - was causing taps-env build failures
  };
}
