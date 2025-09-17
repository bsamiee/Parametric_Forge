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
      brewfile = mkDefault false; # Disable Brewfile (managed via Nix)
      lockfiles = mkDefault false; # Prevent Nix store write attempts
    };
    # --- Activation Behavior ------------------------------------------------
    onActivation = {
      autoUpdate = mkDefault false;
      cleanup = mkDefault "uninstall"; # TESTING: Let Homebrew properly manage apps
      upgrade = mkDefault false; # TESTING: Disable upgrades during activation
      # extraFlags removed - parallel is not a valid homebrew option in nix-darwin
    };
    # --- Essential Taps -----------------------------------------------------
    taps = [
      "koekeishiya/formulae" # For yabai/skhd
      "FelixKratz/formulae" # For borders
      "yqrashawn/goku" # For GokuRakuJoudo (Karabiner EDN compiler)
    ];
    # --- GUI Applications (Casks) -------------------------------------------
    casks = [
      # System & Core Tools
      "1password" # Password manager and secure vault
      "cleanshot" # Advanced screenshot and screen recording tool # TODO: CONFIGURE
      "docker-desktop" # Docker Desktop containerization - CRITICAL for deployment
      "dotnet-sdk" # .NET SDK (large, GUI tools)
      "wezterm" # Terminal emulator - now via Nix with forced TERM=wezterm

      # Productivity & Window Management - MOST ALREADY INSTALLED
      "airbuddy" # AirPods management utility
      "aldente" # Battery charging limiter
      "alt-tab" # Window switching utility
      "bettertouchtool" # Touch/gesture management # TODO: CONFIGURE
      "jordanbaird-ice" # Menu bar manager for macOS
      "raycast" # Launcher/productivity app # TODO: CONFIGURE
      "transnomino" # File renaming utility # TODO: CONFIGURE

      # Browsers & Internet
      "arc" # Arc Browser - Chromium-based browser with innovative UI
      "firefox" # Web browser
      "tor-browser" # Privacy-focused web browser

      # Communication & Social - MIXED
      "discord" # Voice and text communication
      "microsoft-teams" # Microsoft collaboration platform
      "superhuman" # High-performance email client
      "telegram"
      "whatsapp"
      "zoom" # Video conferencing

      # Cloud & Storage - CORRECTED
      "google-drive" # Google cloud storage sync client
      "megasync" # MEGA cloud storage sync client
      "transmission"

      # Development & Design - MIXED
      "heptabase" # Visual knowledge management platform
      "iconjar" # Icon organization and management tool
      "kiro" # Design collaboration and feedback tool
      "rhino-app" # Rhino 8 CAD software
      "typeface" # Font management and typography tool
      "via" # Keyboard configurator for custom keyboards
      "visual-studio-code" # Microsoft's code editor

      # Media & Creative - CORRECTED
      "blender" # 3D creation suite
      "calibre" # E-book management
      "handbrake-app" # MISSING - need homebrew
      "scrivener" # Writing and research tool for authors
      "spotify" # Music streaming service
      "steam" # Gaming platform

      # QuickLook Plugins - DELETED FOR CLEAN HOMEBREW INSTALL
      "syntax-highlight" # Code syntax highlighting for 150+ file types
      "quicklook-json" # JSON formatted preview
      "quicklook-csv" # CSV/TSV table preview
      "betterzip" # Preview ZIP/TAR contents without extracting
      "suspicious-package" # Inspect macOS .pkg installers

      # Fonts
      "font-hack-nerd-font" # Nerd Font with programming symbols
      "font-sf-pro" # SF Pro font family
      "font-sf-arabic" # SF Arabic font family
      "sf-symbols" # SF Symbols 7 - Apple's official symbol library

      # Adobe & Creative Suite - ALREADY INSTALLED
      "adobe-acrobat-pro" # PDF viewer, creator, and editor
      "adobe-creative-cloud" # Adobe creative suite manager and launcher
      "colorchecker-camera-calibration" # X-Rite camera profiling software
      "topaz-gigapixel-ai" # MISSING - need homebrew
      "topaz-photo-ai" # MISSING - need homebrew
      "zxpinstaller" # MISSING - need homebrew

      # Utilities & System Enhancement - MIXED
      "grammarly-desktop" # Grammar and writing assistance tool
      # "parallels" # Windows virtualization for Mac - INSTALL MANUALLY: Homebrew installation incompatible with macOS security requirements
      "rize" # Productivity and time tracking app

      # Automation & Productivity
      "hammerspoon" # Lua-scriptable macOS automation and window management
      "karabiner-elements" # Keyboard remapping (Hyper/Super/Power leaders)
    ];

    # --- CLI Tools (Brews) --------------------------------------------------
    brews = [
      "mas" # Mac App Store CLI for masApps integration
      "handbrake" # CLI video transcoder (GUI in casks as handbrake-app)
      # "mpv" # TODO: Install separately - homebrew fontconfig permission issue
      # "mono" # .NET runtime - RE-INSTALL AFTER FULL DEPLOYMENT (failed during initial setup)
      "defaultbrowser" # CLI tool for setting default browser properly
      "duti" # Declarative file type associations and UTI management

      # Bluetooth Management
      "blueutil" # CLI for Bluetooth management (power, devices, pairing)

      # UI Tools
      "koekeishiya/formulae/yabai"
      "koekeishiya/formulae/skhd"
      "FelixKratz/formulae/borders"
      "yqrashawn/goku/goku" # Goku EDN → karabiner.json (goku/gokuw)

      # File tagging support for Yazi mactag plugin
      "tag" # macOS file tagging CLI (jdberry/tag)
    ];
    # --- Mac App Store Applications -----------------------------------------
    # Disabled: Using smart install/update activation script instead
    # masApps causes unnecessary reinstalls of existing apps
    masApps = {
      # Apps managed via smartMasInstall activation script in activation.nix
    };
    # --- Whalebrew (Docker-based tools) -------------------------------------
    # whalebrews = [ ];

    # --- Cask Configuration -------------------------------------------------
    caskArgs = mkDefault {
      appdir = "/Applications";
      require_sha = false; # Allow casks without SHA (some vendors don't provide)
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
