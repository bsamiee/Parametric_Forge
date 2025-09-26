# Title         : casks.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/casks.nix
# ----------------------------------------------------------------------------
# Homebrew GUI applications

{ ... }:

{
  homebrew.casks = [

    # --- System & Core Tools ------------------------------------------------
    "1password"
    "cleanshot"
    "docker-desktop"
    "dotnet-sdk"          # .NET SDK
    "wezterm"

    # --- Productivity & Window Management -----------------------------------
    "airbuddy"            # AirPods management
    "aldente"             # Battery charging limiter
    "alt-tab"             # Window switching
    "bettertouchtool"     # Touch/gesture management
    "jordanbaird-ice"     # Menu bar manager
    "raycast"             # Launcher/productivity

    # --- Browsers & Internet ------------------------------------------------
    "arc"
    "firefox"
    "tor-browser"

    # --- Communication & Social ---------------------------------------------
    "discord"
    "microsoft-teams"
    "superhuman"          # Email client
    "telegram"
    "whatsapp"
    "zoom"

    # --- Cloud & Storage ----------------------------------------------------
    "google-drive"
    "megasync"

    # --- Development --------------------------------------------------------
    "kiro"
    "visual-studio-code"
    "rhino-app"
    "blender"
    "iconjar"
    "typeface"            # Font management
    "sf-symbols"          # Apple's symbol library

    # --- Media & Entertainment ----------------------------------------------
    "spotify"
    "handbrake-app"       # GUI video transcoder
    "transmission"
    "steam"

    # --- Notes & Reading ----------------------------------------------------
    "calibre"             # E-book management
    "heptabase"           # Knowledge management
    "scrivener"           # Writing tool

    # --- QuickLook Plugins --------------------------------------------------
    "syntax-highlight"    # Code syntax highlighting
    "quicklook-json"      # JSON preview
    "quicklook-csv"       # CSV/TSV preview
    "betterzip"           # Archive preview
    "suspicious-package"  # .pkg inspector

    # --- Fonts --------------------------------------------------------------
    # Programming/Terminal fonts
    "font-hack-nerd-font"
    "font-geist-mono-nerd-font"
    "font-iosevka-nerd-font"
    "font-ibm-plex-mono"           # IBM Plex Mono specifically
    "font-noto-sans-mono"          # Noto monospace variant
    "font-symbols-only-nerd-font"

    # UI/System fonts
    "font-sf-pro"
    "font-sf-arabic"
    "font-geist"
    "font-inter"
    "font-ibm-plex"
    "font-dm-sans"
    "font-overpass"
    "font-source-sans-3"
    "font-source-serif-4"

    # Arabic/Persian fonts
    "font-noto-sans-arabic"
    "font-scheherazade-new"
    "font-markazi-text"
    "font-reem-kufi"
    "font-qahiri"         # Arabic Kufic font

    # Display fonts
    "font-playfair-display"

    # --- Adobe & Creative Suite ---------------------------------------------
    "adobe-acrobat-pro"
    "adobe-creative-cloud"
    "colorchecker-camera-calibration"
    "topaz-gigapixel-ai"
    "topaz-photo-ai"
    "zxpinstaller"

    # --- Utilities & System Enhancement -------------------------------------
    "grammarly-desktop"
    "rize"                # Time tracking
    "via"                 # Keyboard configurator
    "hammerspoon"         # Lua automation
    "karabiner-elements"  # Keyboard remapping
  ];
}
