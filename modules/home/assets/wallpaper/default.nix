# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/assets/wallpaper/default.nix
# ----------------------------------------------------------------------------
# User wallpaper asset and Sonoma-family wallpaper store activation.
# Writes the repo asset to a stable XDG path, points Apple's wallpaper store
# at it, clears per-display/per-space drift, and bounces WallpaperAgent.
{
  config,
  lib,
  pkgs,
  ...
}: let
  wallpaperName = "forge-wallpaper.jpg";
  wallpaperTarget = "${config.xdg.dataHome}/wallpapers/${wallpaperName}";
  wallpaperStore = "${config.home.homeDirectory}/Library/Application Support/com.apple.wallpaper/Store";
  applyWallpaper = pkgs.writeShellApplication {
    name = "forge-apply-wallpaper";
    text = ''
      wallpaper_path="${wallpaperTarget}"
      wallpaper_uri="file://${wallpaperTarget}"
      store_dir="${wallpaperStore}"
      index_plist="${wallpaperStore}/Index.plist"
      pb=/usr/libexec/PlistBuddy

      test -f "$wallpaper_path"
      /bin/mkdir -p "$store_dir"

      # Idempotence: skip the osascript + agent bounce when already applied.
      current="$("$pb" -c "Print :AllSpacesAndDisplays:Desktop:Content:Choices:0:Files:0:relative" "$index_plist" 2>/dev/null || true)"
      displays_lines="$("$pb" -c "Print :Displays" "$index_plist" 2>/dev/null | /usr/bin/wc -l || printf 99)"
      spaces_lines="$("$pb" -c "Print :Spaces" "$index_plist" 2>/dev/null | /usr/bin/wc -l || printf 99)"
      if [ "$current" = "$wallpaper_uri" ] && [ "$displays_lines" -le 2 ] && [ "$spaces_lines" -le 2 ]; then
        exit 0
      fi

      # Materialize a valid current wallpaper structure before normalization.
      /usr/bin/osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$wallpaper_path\""
      /bin/sleep 2
      test -f "$index_plist"

      ensure_dict() {
        "$pb" -c "Print $1" "$index_plist" >/dev/null 2>&1 || \
          "$pb" -c "Add $1 dict" "$index_plist"
      }
      ensure_array() {
        "$pb" -c "Print $1" "$index_plist" >/dev/null 2>&1 || \
          "$pb" -c "Add $1 array" "$index_plist"
      }
      ensure_string() {
        "$pb" -c "Set $1 $2" "$index_plist" 2>/dev/null || \
          "$pb" -c "Add $1 string $2" "$index_plist"
      }

      ensure_dict ":AllSpacesAndDisplays"
      ensure_dict ":AllSpacesAndDisplays:Desktop"
      ensure_dict ":AllSpacesAndDisplays:Desktop:Content"
      ensure_array ":AllSpacesAndDisplays:Desktop:Content:Choices"
      ensure_dict ":AllSpacesAndDisplays:Desktop:Content:Choices:0"
      ensure_array ":AllSpacesAndDisplays:Desktop:Content:Choices:0:Files"
      ensure_dict ":AllSpacesAndDisplays:Desktop:Content:Choices:0:Files:0"

      ensure_string ":AllSpacesAndDisplays:Type" "desktop"
      ensure_string ":AllSpacesAndDisplays:Desktop:Content:Choices:0:Provider" "com.apple.wallpaper.choice.image"
      ensure_string ":AllSpacesAndDisplays:Desktop:Content:Choices:0:Files:0:relative" "$wallpaper_uri"

      # Single-wallpaper policy: clear per-display and per-space specialization.
      "$pb" -c "Delete :Displays" "$index_plist" 2>/dev/null || true
      "$pb" -c "Add :Displays dict" "$index_plist"
      "$pb" -c "Delete :Spaces" "$index_plist" 2>/dev/null || true
      "$pb" -c "Add :Spaces dict" "$index_plist"

      /usr/bin/plutil -lint "$index_plist" >/dev/null
      # WallpaperAgent holds state in memory; a bounce applies the store edit.
      /usr/bin/killall WallpaperAgent 2>/dev/null || true
    '';
  };
in {
  xdg.dataFile."wallpapers/${wallpaperName}".source = ./forge-wallpaper.jpg;

  home.activation.applyForgeWallpaper = lib.hm.dag.entryAfter ["linkGeneration"] ''
    run ${applyWallpaper}/bin/forge-apply-wallpaper
  '';
}
