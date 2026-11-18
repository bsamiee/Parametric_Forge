{lib, ...}: let
  latest = name: {latest = name;};
  rows = [
    # --- [SYSTEM_CORE_TOOLS]
    "1password@nightly"
    "cleanshot"
    (latest "wezterm@nightly")

    # --- [PRODUCTIVITY_WINDOW_MANAGEMENT]
    "airbuddy"
    "aldente"
    "linearmouse@beta"
    "raycast"

    # --- [BROWSERS_INTERNET]
    "arc"
    "firefox@beta"
    "google-chrome"
    "tor-browser@alpha"

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
    "apparency"

    # --- [MEDIA_ENTERTAINMENT]
    "bsamiee/parametric-forge/voicebox"
    "spotify"

    # --- [NOTES_READING]
    "calibre"
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
    (latest "bsamiee/parametric-forge/blender@daily")
    "epic-games"
    "bsamiee/parametric-forge/f3d-app"
    "inkscape"

    # --- [3D_PRINTING]
    "bambu-studio"
    (latest "orcaslicer@nightly")

    # --- [MOTION_AND_REVIEW]
    "cavalry"
    "bsamiee/parametric-forge/mrv2"
    "rive-app/tap/rive-cli"

    # --- [VIRTUALIZATION]
    "parallels"

    # --- [UTILITIES_SYSTEM_ENHANCEMENT]
    "karabiner-elements"
  ];
in {
  homebrew.casks = map (row:
    if lib.isAttrs row
    then {
      name = row.latest;
      greedy = true;
    }
    else row)
  rows;
}
