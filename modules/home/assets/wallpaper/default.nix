# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/assets/wallpaper/default.nix
# ----------------------------------------------------------------------------
# User wallpaper asset applied through System Events; WallpaperAgent owns its
# own store schema, so the apply never edits Index.plist directly.
{
  config,
  lib,
  pkgs,
  ...
}: let
  wallpaperName = "forge-wallpaper.jpg";
  wallpaperTarget = "${config.xdg.dataHome}/wallpapers/${wallpaperName}";
  applyWallpaper = pkgs.writeShellApplication {
    name = "forge-apply-wallpaper";
    text = ''
      wallpaper_path="${wallpaperTarget}"
      test -f "$wallpaper_path"

      current="$(/usr/bin/osascript -e 'tell application "System Events" to get picture of first desktop' 2>/dev/null || true)"
      if [ "$current" = "$wallpaper_path" ]; then exit 0; fi

      /usr/bin/osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$wallpaper_path\""
    '';
  };
in {
  xdg.dataFile."wallpapers/${wallpaperName}".source = ./forge-wallpaper.jpg;

  home.activation.applyForgeWallpaper = lib.hm.dag.entryAfter ["linkGeneration"] ''
    run ${applyWallpaper}/bin/forge-apply-wallpaper
  '';
}
