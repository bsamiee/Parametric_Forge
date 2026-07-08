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
    "cleanshot"
    # Nightly (version :latest) conflicts with the stable "wezterm" cask: hard
    # prerequisite before the first switch is `brew uninstall --cask wezterm`.
    # Pin after install (`brew pin --cask wezterm@nightly`) so the autoupdate
    # daemon never upgrades it implicitly.
    "wezterm@nightly"

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
    "microsoft-auto-update"
    "microsoft-teams"
    "superhuman" # Email client
    "whatsapp"

    # --- Cloud & Storage ----------------------------------------------------
    "google-drive"
    "megasync"

    # --- Development --------------------------------------------------------
    "visual-studio-code"
    "iconjar"
    "typeface" # Font management
    "sf-symbols" # Apple's symbol library

    # --- Media & Entertainment ----------------------------------------------
    "spotify"

    # --- Notes & Reading ----------------------------------------------------
    "calibre" # E-book management
    "heptabase" # Knowledge management
    "scrivener" # Writing tool

    # --- QuickLook Plugins --------------------------------------------------
    # All plugins below use the modern App Extension API (Sequoia-compatible).
    # Legacy .qlgenerator plugins are dead — Sequoia removed support entirely.
    # Note: .ts files are system-reserved (MPEG-2 UTI) — no QL plugin can override this.
    "syntax-highlight" # Source code: 150+ languages (py,js,cs,go,rust,nix,yaml,json,dockerfile,lua,etc.)
    "qlmarkdown" # Rendered markdown preview with GitHub-style formatting
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
    "zxpinstaller"

    # --- Utilities & System Enhancement -------------------------------------
    "grammarly-desktop"
    "rize" # Time tracking
    "hammerspoon" # Lua automation
    "karabiner-elements" # Keyboard remapping
  ];
}
