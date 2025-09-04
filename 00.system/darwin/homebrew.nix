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
      "FelixKratz/formulae"  # For sketchybar/borders
    ];
    # --- GUI Applications (Casks) -------------------------------------------
    casks = [
      # System & Core Tools
      # "1password" # Already installed manually
      # "1password-cli" # Moved to nix packages (sysadmin.nix)
      # "cleanshot" # Already installed manually
      "docker-desktop" # Docker Desktop containerization - CRITICAL for deployment
      "dotnet-sdk" # .NET SDK (large, GUI tools)
      # "wezterm@nightly" # Already have WezTerm manually

      # Productivity & Window Management - MOST ALREADY INSTALLED
      "airbuddy" # AirPods management utility
      "aldente" # Battery charging limiter
      "alt-tab" # Window switching utility
      "bettermouse" # Mouse enhancement utility
      "bettertouchtool" # Touch/gesture management
      "hazel" # File organization automation
      "latest" # App update checker
      "raycast" # Launcher/productivity app
      "superkey" # Keyboard enhancement utility
      "swish" # Trackpad gesture utility
      "transnomino" # File renaming utility

      # Browsers & Internet
      "firefox" # Web browser
      "tor-browser" # Privacy-focused web browser
      "zen" # Zen Browser - Firefox-based with Arc-like features

      # Communication & Social - MIXED
      "discord" # Voice and text communication
      # "microsoft-teams" # Already installed manually
      # "superhuman" # Already installed manually
      "telegram" # MISSING - need homebrew
      "whatsapp" # MISSING - need homebrew
      "zoom" # MISSING - need homebrew

      # Cloud & Storage - CORRECTED
      # "google-drive" # Already installed manually
      # "megasync" # Already installed manually (MEGAsync.app)
      "transmission" # MISSING - need homebrew

      # Development & Design - MIXED
      # "heptabase" # Already installed manually
      # "iconjar" # Already installed manually
      # "kiro" # Already installed manually
      # "replacicon" # Already installed manually
      "rhino-app" # Rhino 8 CAD software
      # "typeface" # Already installed manually
      # "via" # Already installed manually
      # "visual-studio-code" # Already installed manually

      # Media & Creative - CORRECTED
      "blender" # 3D creation suite
      "calibre" # E-book management
      "handbrake-app" # MISSING - need homebrew
      # "scrivener" # Already installed manually
      "spotify" # Music streaming service
      "steam" # Gaming platform

      # QuickLook Plugins - DELETED FOR CLEAN HOMEBREW INSTALL
      "syntax-highlight" # Code syntax highlighting for 150+ file types
      "quicklook-json" # JSON formatted preview
      "quicklook-csv" # CSV/TSV table preview
      "betterzip" # Preview ZIP/TAR contents without extracting
      "suspicious-package" # Inspect macOS .pkg installers

      # Fonts for SketchyBar
      "font-hack-nerd-font" # Default SketchyBar font

      # Adobe & Creative Suite - ALREADY INSTALLED
      # "adobe-acrobat-pro" # Already installed manually
      # "adobe-creative-cloud" # Already installed manually
      # "colorchecker-camera-calibration" # Already installed manually
      "topaz-gigapixel-ai" # MISSING - need homebrew
      "topaz-photo-ai" # MISSING - need homebrew
      "zxpinstaller" # MISSING - need homebrew

      # Utilities & System Enhancement - MIXED
      # "grammarly-desktop" # Already installed manually
      # "parallels" # Already installed manually
      # "rize" # Already installed manually

      # Automation & Productivity
      "hammerspoon" # Lua-scriptable macOS automation and window management

      # Battery Management
      "battery" # Battery management app with CLI (required for SketchyBar battery plugin)
    ];

    # --- CLI Tools (Brews) --------------------------------------------------
    brews = [
      "mas" # Mac App Store CLI for masApps integration
      "codex" # AI coding assistant (ChatGPT CLI)
      "handbrake" # CLI video transcoder (GUI in casks as handbrake-app)
      # "mono" # .NET runtime - RE-INSTALL AFTER FULL DEPLOYMENT (failed during initial setup)
      "defaultbrowser" # CLI tool for setting default browser properly
      "duti" # Declarative file type associations and UTI management
      # "alerter" # REMOVED - formula doesn't exist in Homebrew

      # System Monitoring
      "macmon" # macOS system monitoring tool (for SketchyBar plugins)

      # Bluetooth Management
      "blueutil" # CLI for Bluetooth management (power, devices, pairing)

      # UI Tools
      "koekeishiya/formulae/yabai"
      "koekeishiya/formulae/skhd"
      "FelixKratz/formulae/sketchybar"
      "FelixKratz/formulae/borders"
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
