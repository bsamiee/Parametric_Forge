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
      cleanup = mkDefault "uninstall";
      upgrade = mkDefault false;
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
      "1password"
      "cleanshot"
      "docker-desktop"
      "dotnet-sdk" # .NET SDK (large, GUI tools)
      "wezterm"
      # "parallels" # Windows virtualization for Mac - INSTALL MANUALLY: Homebrew installation incompatible with macOS security requirements

      # Productivity & Window Management - MOST ALREADY INSTALLED
      "airbuddy" # AirPods management utility
      "aldente" # Battery charging limiter
      "alt-tab" # Window switching utility
      "bettertouchtool" # Touch/gesture management # TODO: CONFIGURE
      "jordanbaird-ice" # Menu bar manager for macOS
      "raycast" # Launcher/productivity app # TODO: CONFIGURE
      "transnomino" # File renaming utility # TODO: CONFIGURE

      # Browsers & Internet
      "arc"
      "firefox"
      "tor-browser"

      # Communication & Social - MIXED
      "discord"
      "microsoft-teams"
      "superhuman" # Email client
      "telegram"
      "whatsapp"
      "zoom"

      # Cloud & Storage - CORRECTED
      "google-drive"
      "megasync"
      "transmission"

      # Development
      "kiro"
      "visual-studio-code"
      "rhino-app"
      "blender" # 3D creation suite
      "iconjar"
      "typeface" # Font management and typography tool

      # Media & Entertainment - CORRECTED
      "spotify" # Music streaming service
      "handbrake-app" # MISSING - need homebrew
      "steam" # Gaming platform

      # Notes & Reading
      "calibre" # E-book management
      "heptabase" # Note-taking and knowledge management
      "scrivener" # Writing and research tool for authors

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
      "topaz-gigapixel-ai"
      "topaz-photo-ai"
      "zxpinstaller"

      # Utilities & System Enhancement - MIXED
      "grammarly-desktop" # Grammar and writing assistance tool
      "rize" # Productivity and time tracking app
      "via" # Keyboard configurator for custom keyboards

      # Automation & Productivity
      "hammerspoon" # Lua-scriptable macOS automation and window management
      "karabiner-elements" # Keyboard remapping (Hyper/Super/Power leaders)
    ];

    # --- CLI Tools (Brews) --------------------------------------------------
    brews = [
      "mas" # Mac App Store CLI for masApps integration
      "handbrake" # CLI video transcoder (GUI in casks as handbrake-app)
      # "mono" # .NET runtime - RE-INSTALL AFTER FULL DEPLOYMENT (failed during initial setup)
      "defaultbrowser" # CLI tool for setting default browser properly
      "duti" # Declarative file type associations and UTI management
      "tag" # macOS file tagging CLI (jdberry/tag)
      "blueutil" # CLI for Bluetooth management (power, devices, pairing)

      # UI Tools
      "koekeishiya/formulae/yabai"
      "koekeishiya/formulae/skhd"
      "FelixKratz/formulae/borders"
      "yqrashawn/goku/goku" # Goku EDN → karabiner.json (goku/gokuw)

      # Shell enhancements
      "thefuck" # Command correction tool (Python 3.12 incompatible in nixpkgs)
    ];
    # --- Mac App Store Applications -----------------------------------------
    masApps = {
      # Apps managed via smartMasInstall activation script in activation.nix - deprecated for now
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
