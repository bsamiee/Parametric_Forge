# Title         : casks.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/casks.nix
# ----------------------------------------------------------------------------
# Homebrew GUI applications, and the Apple-proprietary faces (no nixpkgs source) that font casks install into ~/Library/Fonts. Google OFL
# families live in the operator design-tools store (Typeface-indexed), never here.
_: {
  homebrew.casks = [
    # --- [SYSTEM_CORE_TOOLS]
    "1password"
    "cleanshot"
    # Nightly conflicts with the stable cask; a :latest cask never reads outdated, so `brew upgrade --greedy-latest wezterm@nightly` refreshes it.
    "wezterm@nightly"

    # --- [PRODUCTIVITY_WINDOW_MANAGEMENT]
    "airbuddy" # AirPods management
    "aldente" # Battery charging limiter
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
    "onedrive"

    # --- [DEVELOPMENT]
    "codex" # Official OpenAI CLI cask
    "visual-studio-code"
    # Typeface Beta is installed and updated through its native vendor channel.
    "sf-symbols" # Apple's symbol library

    # --- [MEDIA_ENTERTAINMENT]
    "spotify"

    # --- [NOTES_READING]
    "calibre" # E-book management
    "heptabase" # Knowledge management
    "scrivener" # Writing tool

    # --- [QUICKLOOK_PLUGINS]
    # Plugins below use the App Extension API; legacy .qlgenerator plugins are dead since Sequoia. Each app registers its extension on
    # its first launch, and .ts files are system-reserved (MPEG-2 UTI), so no QL plugin can override them.
    "syntax-highlight" # Source code: 150+ languages (py,js,cs,go,rust,nix,yaml,json,dockerfile,lua,etc.)
    "qlmarkdown" # Rendered markdown preview with GitHub-style formatting
    "betterzip" # Archive preview, Finder extension, and the betterzip command-line tool
    "suspicious-package" # .pkg inspector

    # --- [FONTS]
    "font-sf-pro" # Apple proprietary
    "font-sf-arabic" # Apple proprietary

    # --- [ADOBE_CREATIVE_SUITE]
    "bsamiee/forge/aescripts-zxp-installer" # CEP and UXP extension installer; the qualified name scopes the module's default trust to this cask

    # --- [UTILITIES_SYSTEM_ENHANCEMENT]
    "karabiner-elements" # Keyboard remapping
  ];
}
