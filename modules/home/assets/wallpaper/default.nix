# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/assets/wallpaper/default.nix
# ----------------------------------------------------------------------------
# User wallpaper asset applied through System Events; WallpaperAgent owns its own store schema, so the apply never edits Index.plist directly.
# Policy: one wallpaper on every desktop; restore path is System Settings > Wallpaper.
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
    runtimeInputs = [pkgs.coreutils];
    text = ''
      wallpaper_path="${wallpaperTarget}"
      if [ ! -f "$wallpaper_path" ]; then
        echo "forge-apply-wallpaper: missing asset $wallpaper_path (linkGeneration owns it)" >&2
        exit 66
      fi
      # WallpaperAgent stores the physical file behind the XDG symlink, so a converged desktop reports the resolved store path — accept either
      # form, and a content change (new store hash) still reads as divergence.
      resolved_path="$(readlink -f "$wallpaper_path")"

      # One truthful verdict over every desktop System Events exposes (one per active display, current Space; further Spaces are outside its
      # surface). Non-comparable pictures (dynamic/aerial, missing value) are divergence.
      probe() {
        /usr/bin/osascript - "$wallpaper_path" "$resolved_path" 2>&1 <<'APPLESCRIPT'
      on run argv
        set target to item 1 of argv
        set resolved to item 2 of argv
        tell application "System Events" to set pics to picture of every desktop
        repeat with p in pics
          try
            if (p as text) is not equal to target and (p as text) is not equal to resolved then return "apply " & (count of pics)
          on error
            return "apply " & (count of pics)
          end try
        end repeat
        return "converged " & (count of pics)
      end run
      APPLESCRIPT
      }

      if ! verdict_line="$(probe)"; then
        case "$verdict_line" in
          *-1743* | *-1744* | *"Not authorized"* | *"not allowed"*)
            echo "forge-apply-wallpaper: TCC Automation grant missing for System Events" >&2
            echo "forge-apply-wallpaper: grant once: System Settings > Privacy & Security > Automation > (calling app) > System Events" >&2
            exit 77
            ;;
          *)
            echo "forge-apply-wallpaper: desktop probe failed: $verdict_line" >&2
            exit 1
            ;;
        esac
      fi

      desktops="''${verdict_line##* }"
      if [ "''${verdict_line%% *}" = "converged" ]; then
        printf 'forge-apply-wallpaper: receipt\tdesktops=%s\taction=none\tstate=converged\n' "$desktops"
        exit 0
      fi

      # Setter passes the path through argv like the probe; source-text interpolation would break on quote-bearing paths.
      /usr/bin/osascript - "$wallpaper_path" <<'APPLESCRIPT'
      on run argv
        tell application "System Events" to tell every desktop to set picture to (POSIX file (item 1 of argv))
      end run
      APPLESCRIPT

      # Re-probe keeps the receipt truthful; WallpaperAgent can apply asynchronously, so an unconverged re-probe is recorded, never fatal.
      state=set-unverified
      if post="$(probe)" && [ "''${post%% *}" = "converged" ]; then state=applied; fi
      printf 'forge-apply-wallpaper: receipt\tdesktops=%s\taction=set-every-desktop\tstate=%s\trestore=System Settings > Wallpaper\n' "$desktops" "$state"
    '';
  };
in {
  # Installed operator surface: rerun after a one-time TCC grant without a full switch; activation and manual runs share the identical receipt contract.
  home.packages = [applyWallpaper];

  xdg.dataFile."wallpapers/${wallpaperName}".source = ./forge-wallpaper.jpg;

  home.activation.applyForgeWallpaper = lib.hm.dag.entryAfter ["linkGeneration"] ''
    run ${applyWallpaper}/bin/forge-apply-wallpaper
  '';
}
