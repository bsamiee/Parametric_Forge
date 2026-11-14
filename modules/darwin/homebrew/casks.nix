{lib, ...}: let
  latest = name: {latest = name;};
  rows = [
    # --- [SYSTEM_CORE_TOOLS]
    (latest "1password@nightly")
    "cleanshot"
    (latest "wezterm@nightly")

    # --- [PRODUCTIVITY_WINDOW_MANAGEMENT]
    "airbuddy"
    "aldente"
    "linearmouse@beta"
    "raycast"

    # --- [BROWSERS_INTERNET]
    "arc"
    "firefox"
    "google-chrome"
    "tor-browser"

    # --- [NETWORK]
    "tailscale-app"

    # --- [COMMUNICATION_SOCIAL]
    "discord"
    "microsoft-auto-update"
    "microsoft-teams"
    "superhuman"
    "whatsapp"

    # --- [CLOUD_STORAGE]
    "google-drive"
    "megasync"
    "onedrive"

    # --- [DEVELOPMENT]
    "visual-studio-code"
    "sf-symbols"

    # --- [MEDIA_ENTERTAINMENT]
    "bsamiee/forge/voicebox"
    "spotify"

    # --- [NOTES_READING]
    "calibre"
    "heptabase"
    "libreoffice"
    "scrivener"

    # --- [QUICKLOOK_PLUGINS]
    "syntax-highlight"
    "qlmarkdown"
    "betterzip"
    "suspicious-package"

    # --- [FONTS]
    (latest "font-sf-pro")
    (latest "font-sf-arabic")
    (latest "font-markazi-text")
    (latest "font-reem-kufi")
    (latest "font-qahiri")

    # --- [3D_CREATION]
    (latest "bsamiee/forge/blender@daily")
    "epic-games"
    "inkscape"
    "xquartz"

    # --- [UTILITIES_SYSTEM_ENHANCEMENT]
    "cuadriver"
    "karabiner-elements"
  ];
in {
  options.forge.homebrew.latestCasks = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    default = map (row: lib.last (lib.splitString "/" row.latest)) (lib.filter lib.isAttrs rows);
    description = "Casks without a version, which `brew upgrade` moves only when named greedy.";
  };

  config.homebrew.casks = map (row: row.latest or row) rows;
}
