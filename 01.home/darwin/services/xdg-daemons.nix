# Title         : 01.home/darwin/services/xdg-daemons.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/xdg-daemons.nix
# ----------------------------------------------------------------------------
# XDG runtime directory maintenance and cache cleanup daemons.

{
  config,
  lib,
  pkgs,
  myLib,
  userServiceHelpers,
  exclusions,
  exclusionFilters,
  ...
}:

let
  # --- Service Helper Functions ---------------------------------------------
  inherit (userServiceHelpers) mkPeriodicJob mkCalendarJob;
  inherit (myLib.launchd) getRuntimeDir;
  inherit (exclusionFilters) byLocation getPatterns;

  # --- Cache Configuration --------------------------------------------------
  cacheInXdg = byLocation "xdg-cache" exclusions;
  cacheDirs = getPatterns cacheInXdg;

  # --- Runtime Directory Path -----------------------------------------------
  runtimeDir = getRuntimeDir pkgs;

  # --- Font Cache State Management ------------------------------------------
  fontStateFile = "${config.xdg.stateHome}/font-cache.state";
  fontDirs = [
    "/System/Library/Fonts"
    "/Library/Fonts"
    "/run/current-system/sw/share/fonts"
    "${config.home.profileDirectory}/share/fonts" # Home-manager fonts (including patched fonts)
    "${config.home.homeDirectory}/Library/Fonts" # User-installed fonts
  ];
in
{
  # --- XDG Runtime Directory Maintenance ------------------------------------
  launchd.agents."org.nixos.xdg-runtime" = {
    enable = true;
    config = mkPeriodicJob {
      interval = 3600;
      nice = 15;
      script = ''
        echo "[$(date)] Starting runtime and temp directory cleanup..."

        # Basic Runtime Directory Cleanup
        find "${runtimeDir}" -type f -mtime +1 -delete 2>/dev/null || true
        find "${runtimeDir}" -type d -empty -delete 2>/dev/null || true

        # Extended Temp Cleanup (every 2 hours)
        LAST_RUN_FILE="${config.xdg.stateHome}/temp-cleanup.last"
        CURRENT_HOUR=$(date +%H)

        # Only run extended cleanup every 2 hours
        if [ ! -f "$LAST_RUN_FILE" ] || [ $(( $(date +%s) - $(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0) )) -gt 7200 ]; then
          echo "  Running extended temp cleanup..."

          # Clean npm temp
          NPM_TMP="${config.xdg.cacheHome}/npm-tmp"
          [ -d "$NPM_TMP" ] && {
            find "$NPM_TMP" -type f -mtime +1 -delete 2>/dev/null || true
            find "$NPM_TMP" -type d -empty -delete 2>/dev/null || true
          }

          # Clean build artifacts
          [ -d "${runtimeDir}" ] && {
            find "${runtimeDir}" -maxdepth 1 -name "nix-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "${runtimeDir}" -maxdepth 1 -name "npm-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "${runtimeDir}" -maxdepth 1 -name "node-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "${runtimeDir}" -maxdepth 1 -name "yarn-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "${runtimeDir}" -maxdepth 1 -name "pip-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true

            # Clean editor temps and sockets
            ls -t ${runtimeDir}/vscode-ipc-* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
            find "${runtimeDir}" -name "*.sw[pon]" -mtime +1 -delete 2>/dev/null || true
            find "${runtimeDir}" -type s -mtime +1 -delete 2>/dev/null || true
            find "${runtimeDir}" -type p -mtime +1 -delete 2>/dev/null || true
          }

          date +%s > "$LAST_RUN_FILE"
        fi

        echo "[$(date)] Runtime cleanup completed"
      '';
      logBaseName = "${config.xdg.stateHome}/logs/xdg-runtime";
      runAtLoad = true;
    };
  };
  # --- XDG Cache Cleanup Agent ----------------------------------------------
  launchd.agents."org.nixos.xdg-cache-cleanup" = {
    enable = true;
    config = mkCalendarJob {
      calendar = [
        {
          Weekday = 1;
          Hour = 3;
          Minute = 30;
        }
        {
          Weekday = 4;
          Hour = 3;
          Minute = 30;
        }
      ];
      nice = 19;
      script = ''
        echo "Starting XDG cache cleanup at $(date)"

        find "${config.xdg.cacheHome}" -type f -atime +30 -delete 2>/dev/null || true
        find "${config.xdg.cacheHome}" -type d -empty -delete 2>/dev/null || true

        ${lib.concatMapStrings (dir: ''
          if [ -d "${config.xdg.cacheHome}/${dir}" ]; then
            find "${config.xdg.cacheHome}/${dir}" -type f -atime +30 -delete 2>/dev/null || true
            find "${config.xdg.cacheHome}/${dir}" -type d -empty -delete 2>/dev/null || true
          fi
        '') cacheDirs}

        # Font Cache Management
        FONT_CACHE="${config.xdg.cacheHome}/fontconfig"
        STATE_FILE="${fontStateFile}"
        FONT_REFRESH=0

        # Calculate current font state hash
        CURRENT_STATE=$(find ${lib.concatStringsSep " " fontDirs} \
          -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" \) \
          -exec stat -f "%m %z %N" {} \; 2>/dev/null \
          | sort | ${pkgs.coreutils}/bin/sha256sum | cut -d' ' -f1)

        # Read previous state
        [ -f "$STATE_FILE" ] || touch "$STATE_FILE"
        PREV_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "")

        # Content-aware refresh
        if [ "$CURRENT_STATE" != "$PREV_STATE" ]; then
          echo "Font changes detected, refreshing cache..."
          [ -d "$FONT_CACHE" ] && rm -rf "''${FONT_CACHE:?}"/*
          ${pkgs.fontconfig}/bin/fc-cache -rfv
          echo "$CURRENT_STATE" > "$STATE_FILE"
          FONT_REFRESH=1
        elif [ -d "$FONT_CACHE" ]; then
          # Size-based cleanup as fallback
          SIZE=$(du -sm "$FONT_CACHE" 2>/dev/null | cut -f1)
          if [ "$SIZE" -gt 200 ] 2>/dev/null; then
            echo "Font cache is ''${SIZE}MB, cleaning..."
            rm -rf "''${FONT_CACHE:?}"/*
            ${pkgs.fontconfig}/bin/fc-cache -rfv
            echo "$CURRENT_STATE" > "$STATE_FILE"
            FONT_REFRESH=1
          fi
        fi

        # Legacy Cache Cleanup
        if [ -d "${config.home.homeDirectory}/.npm" ]; then
          find "${config.home.homeDirectory}/.npm" -type f -atime +14 -delete 2>/dev/null || true
        fi

        # Log Rotation
        find "${config.xdg.stateHome}/logs" -name "*.log" -mtime +30 -delete 2>/dev/null || true

        echo "XDG cache cleanup completed at $(date)"

        # Send notification for significant operations
        if [ $FONT_REFRESH -eq 1 ]; then
          alerter -title "Cache Maintenance" -message "Font cache refreshed successfully" -appIcon "/System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns" -sound Tink -timeout 3
        fi
      '';
      logBaseName = "${config.xdg.stateHome}/logs/xdg-cleanup";
    };
  };
}
