# Title         : casks.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/casks.nix
# ----------------------------------------------------------------------------
# Homebrew GUI applications, and the faces with no nixpkgs source that font casks install into ~/Library/Fonts: the Apple-proprietary
# families and the Google OFL Arabic-script families the design apps need permanently active (the design-tools store is Typeface-activated
# on demand, so a store copy never reaches an app font menu on its own).
_: {
  homebrew.casks = [
    # --- [SYSTEM_CORE_TOOLS]
    "1password"
    "cleanshot"
    # Nightly conflicts with the stable cask; a :latest cask never reads outdated, so only a greedy upgrade refreshes it.
    {
      name = "wezterm@nightly";
      greedy = true;
    }

    # --- [PRODUCTIVITY_WINDOW_MANAGEMENT]
    "airbuddy" # AirPods management
    "aldente" # Battery charging limiter
    # Beta cask conflicts with the stable cask; it tracks the Sparkle beta feed the app follows, so Homebrew's record and the app agree.
    "linearmouse@beta" # Mouse pointer/scroll engine; config declared in home/programs/apps/linearmouse
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
    "docker-desktop" # VI-Suite FloVi probes /Applications/Docker.app; Colima stays the DOCKER_HOST owner and the Nix profile precedes its /usr/local/bin links
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
    "font-markazi-text" # Persian/Arabic naskh text face, variable weight
    "font-reem-kufi" # Arabic kufi display face, variable weight
    "font-qahiri" # Arabic kufic display face

    # --- [ADOBE_CREATIVE_SUITE]
    "bsamiee/forge/aescripts-zxp-installer" # CEP and UXP extension installer; the qualified name scopes the module's default trust to this cask

    # --- [3D_CREATION]
    "bsamiee/forge/blender@daily" # 3D creation suite at the newest daily build of the main branch, pinned in Casks/blender@daily.rb; the cask links its blender command wrapper into /opt/homebrew/bin
    "epic-games" # Epic Games Launcher; Unreal Engine and Twinmotion install into /Users/Shared/Epic Games and update through it, and the launcher self-updates, so activation only realigns Homebrew's record
    "inkscape" # Bonsai's SVG to DXF/PDF sheet converter, read at its app bundle; the cask links its inkscape command wrapper into /opt/homebrew/bin
    "xquartz" # X11 server the VI-Suite LiVi preview (Radiance rvu) opens its window on

    # --- [UTILITIES_SYSTEM_ENHANCEMENT]
    "karabiner-elements" # Keyboard remapping
  ];
}
