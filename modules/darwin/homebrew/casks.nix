# Title         : casks.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/casks.nix
# ----------------------------------------------------------------------------
# Homebrew GUI applications, and fonts not available in nixpkgs.
_: {
  homebrew.casks = [
    # --- [SYSTEM_CORE_TOOLS]
    "1password"
    "cleanshot"
    # Nightly (version :latest) conflicts with the stable "wezterm" cask: hard prerequisite before the first switch is `brew uninstall --cask wezterm`.
    # Pin after install (`brew pin --cask wezterm@nightly`) so the autoupdate daemon never upgrades it implicitly.
    "wezterm@nightly"

    # --- [PRODUCTIVITY_WINDOW_MANAGEMENT]
    "airbuddy" # AirPods management
    "aldente" # Battery charging limiter
    "bettertouchtool" # Touch/gesture management
    "jordanbaird-ice" # Menu bar manager
    "linearmouse" # Mouse pointer/scroll engine; config declared in home/programs/apps/linearmouse
    "raycast" # Launcher/productivity

    # --- [BROWSERS_INTERNET]
    "arc"
    "firefox"
    "tor-browser"

    # --- [COMMUNICATION_SOCIAL]
    "discord"
    "microsoft-auto-update"
    "microsoft-teams"
    "superhuman" # Email client
    "whatsapp"

    # --- [CLOUD_STORAGE]
    "google-drive"
    "megasync"

    # --- [DEVELOPMENT]
    "visual-studio-code"
    "iconjar"
    "typeface" # Font management
    "sf-symbols" # Apple's symbol library

    # --- [MEDIA_ENTERTAINMENT]
    "spotify"

    # --- [NOTES_READING]
    "calibre" # E-book management
    "heptabase" # Knowledge management
    "scrivener" # Writing tool

    # --- [QUICKLOOK_PLUGINS]
    # Plugins below use the App Extension API (Sequoia-compatible); legacy .qlgenerator plugins are dead — Sequoia removed support entirely.
    # .ts files are system-reserved (MPEG-2 UTI), so no QL plugin can override them.
    "syntax-highlight" # Source code: 150+ languages (py,js,cs,go,rust,nix,yaml,json,dockerfile,lua,etc.)
    "qlmarkdown" # Rendered markdown preview with GitHub-style formatting
    "betterzip" # Archive preview
    "suspicious-package" # .pkg inspector

    # --- [FONTS]
    "font-playfair-display"
    "font-sf-pro" # Apple proprietary
    "font-sf-arabic" # Apple proprietary
    "font-markazi-text"
    "font-reem-kufi"
    "font-qahiri"

    # --- [ADOBE_CREATIVE_SUITE]
    "zxpinstaller"

    # --- [UTILITIES_SYSTEM_ENHANCEMENT]
    "grammarly-desktop"
    "rize" # Time tracking
    "hammerspoon" # Lua automation
    "karabiner-elements" # Keyboard remapping
  ];
}
