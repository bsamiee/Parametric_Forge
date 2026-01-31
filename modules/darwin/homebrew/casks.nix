# Title         : casks.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/casks.nix
# ----------------------------------------------------------------------------
# Homebrew GUI applications
_: {
  homebrew.casks = [
    # --- System & Core Tools ------------------------------------------------
    "1password"
    "1password-cli"
    "cleanshot"
    "docker-desktop"
    "wezterm"

    # --- Productivity & Window Management -----------------------------------
    "airbuddy" # AirPods management
    "aldente" # Battery charging limiter
    "alt-tab" # Window switching
    "bettertouchtool" # Touch/gesture management
    "jordanbaird-ice" # Menu bar manager
    "raycast" # Launcher/productivity

    # --- Browsers & Internet ------------------------------------------------
    "arc"
    "firefox"
    "tor-browser"

    # --- Communication & Social ---------------------------------------------
    "discord"
    "microsoft-teams"
    "superhuman" # Email client
    # "telegram"
    "whatsapp"
    # "zoom"

    # --- Cloud & Storage ----------------------------------------------------
    "google-drive"
    "megasync"

    # --- Development --------------------------------------------------------
    "visual-studio-code"
    # "blender"
    "iconjar"
    "typeface" # Font management
    "sf-symbols" # Apple's symbol library

    # --- Media & Entertainment ----------------------------------------------
    "spotify"
    # "handbrake-app" # GUI video transcoder
    # "transmission"
    # "steam"

    # --- Notes & Reading ----------------------------------------------------
    "calibre" # E-book management
    "heptabase" # Knowledge management
    "scrivener" # Writing tool

    # --- QuickLook Plugins --------------------------------------------------
    "syntax-highlight" # Code syntax highlighting
    "quicklook-json" # JSON preview
    "quicklook-csv" # CSV/TSV preview
    "betterzip" # Archive preview
    "suspicious-package" # .pkg inspector

    # --- Fonts --------------------------------------------------------------
    # Fonts not available in nixpkgs:
    "font-playfair-display" # Not available as standalone package
    "font-sf-pro" # Apple proprietary
    "font-sf-arabic" # Apple proprietary
    "font-markazi-text" # Not in nixpkgs
    "font-reem-kufi" # Not in nixpkgs
    "font-qahiri" # Not in nixpkgs

    # --- Adobe & Creative Suite ---------------------------------------------
    # "adobe-acrobat-pro"
    # "adobe-creative-cloud"
    # "colorchecker-camera-calibration"
    "zxpinstaller"

    # --- Utilities & System Enhancement -------------------------------------
    "grammarly-desktop"
    "rize" # Time tracking
    "via" # Keyboard configurator
    "hammerspoon" # Lua automation
    "karabiner-elements" # Keyboard remapping
  ];
}
