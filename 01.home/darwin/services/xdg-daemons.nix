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
  ...
}:

let
  # --- Service Helper Functions ---------------------------------------------
  inherit (userServiceHelpers) mkPeriodicJob mkCalendarJob;
  inherit (myLib.launchd) getRuntimeDir;

  # --- Common Cache Directories (simplified, no exclusion system) -----------
  cacheDirs = [
    "npm"
    "pnpm"
    "yarn"
    "pip"
    "pypoetry"
    "pylint"
    "ruff"
    "basedpyright"
    "mypy"
    "pytest"
    "uv"
    "cargo"
    "rust-analyzer"
    "sccache"
    "go-build"
    "gradle"
    "maven"
    "docker"
    "colima"
    "podman"
    "lazydocker"
    "dive"
    "buildkit"
    "bat"
    "direnv"
    "fd"
    "nix-index"
    "nix"
    "fontconfig"
    "shellcheck"
    "bazel"
    "op"
    "ssh"
    "claude"
    "sqlite_history"
  ];

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
  launchd.agents."org.nixos.xdg-temp-cleanup" = {
    enable = true;
    config = mkPeriodicJob {
      label = "XDG Cleanup Daemon";
      interval = 3600;
      nice = 15;
      command = "${
        pkgs.writeShellApplication {
          name = "xdg-cleanup-daemon";
          text = ''
            echo "[$(date)] Starting runtime and temp directory cleanup..."

            # Basic Runtime Directory Cleanup
            find "${runtimeDir}" -type f -mtime +1 -delete 2>/dev/null || true
            find "${runtimeDir}" -type d -empty -delete 2>/dev/null || true

            # Extended Temp Cleanup (every 2 hours)
            LAST_RUN_FILE="${config.xdg.stateHome}/temp-cleanup.last"

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
                find "${runtimeDir}" -name "vscode-ipc-*" -type f -mtime +1 -delete 2>/dev/null || true
                find "${runtimeDir}" -name "*.sw[pon]" -mtime +1 -delete 2>/dev/null || true
                find "${runtimeDir}" -type s -mtime +1 -delete 2>/dev/null || true
                find "${runtimeDir}" -type p -mtime +1 -delete 2>/dev/null || true
              }

              date +%s > "$LAST_RUN_FILE"
            fi

            echo "[$(date)] Runtime cleanup completed"
          '';
        }
      }/bin/xdg-cleanup-daemon";
      logBaseName = "${config.xdg.stateHome}/logs/xdg-runtime";
      runAtLoad = true;
    };
  };
  # --- XDG Cache Cleanup Agent ----------------------------------------------
  launchd.agents."org.nixos.font-cache-manager" = {
    enable = true;
    config = mkCalendarJob {
      label = "Font Cache Daemon";
      calendar = [
        {
          Weekday = 1;
          Hour = 3;
          Minute = 45;  # Avoid 3:00 (Nix GC), 3:30 (other services)
        }
        {
          Weekday = 4;
          Hour = 3;
          Minute = 45;
        }
      ];
      nice = 19;
      command = "${
        pkgs.writeShellApplication {
          name = "font-cache-daemon";
          text = ''
            echo "Starting XDG cache cleanup at $(date)"

            find "${config.xdg.cacheHome}" -type f -atime +30 -delete 2>/dev/null || true
            find "${config.xdg.cacheHome}" -type d -empty -delete 2>/dev/null || true

            # Cache-specific cleanup with size limits
            ${lib.concatMapStrings (dir: let
              sizeLimit = {
                npm = "500";     # 500MB limit for npm
                cargo = "1000";  # 1GB limit for cargo
                pip = "300";     # 300MB limit for pip
                mypy = "200";    # 200MB limit for mypy
                go-build = "400"; # 400MB limit for go
              }.${dir} or "100"; # Default 100MB limit
            in ''
              if [ -d "${config.xdg.cacheHome}/${dir}" ]; then
                # Size-based cleanup first
                SIZE=$(du -sm "${config.xdg.cacheHome}/${dir}" 2>/dev/null | cut -f1 || echo "0")
                if [ "$SIZE" -gt ${sizeLimit} ] 2>/dev/null; then
                  echo "  ${dir} cache is ''${SIZE}MB (limit: ${sizeLimit}MB), cleaning..."
                  find "${config.xdg.cacheHome}/${dir}" -type f -atime +7 -delete 2>/dev/null || true
                fi
                # Age-based cleanup
                find "${config.xdg.cacheHome}/${dir}" -type f -atime +30 -delete 2>/dev/null || true
                find "${config.xdg.cacheHome}/${dir}" -type d -empty -delete 2>/dev/null || true
              fi
            '') cacheDirs}

            # Font Cache Management
            FONT_CACHE="${config.xdg.cacheHome}/fontconfig"
            STATE_FILE="${fontStateFile}"
            FONT_REFRESH=0

            # Fast directory mtime check first (avoid expensive file enumeration)
            DIR_STATE=""
            for dir in ${lib.concatStringsSep " " fontDirs}; do
              if [ -d "$dir" ]; then
                DIR_MTIME=$(stat -f "%m" "$dir" 2>/dev/null || echo "0")
                DIR_STATE="$DIR_STATE:$dir:$DIR_MTIME"
              fi
            done
            
            # Read state file once
            [ -f "$STATE_FILE" ] || touch "$STATE_FILE"
            {
              read -r PREV_STATE || PREV_STATE=""
              read -r PREV_DIR_STATE || PREV_DIR_STATE=""
            } < "$STATE_FILE"
            
            # Only compute expensive hash if directories changed
            if [ "$DIR_STATE" != "$PREV_DIR_STATE" ]; then
              echo "Font directory changes detected, computing file hash..."
              CURRENT_STATE=$(find ${lib.concatStringsSep " " fontDirs} \
                -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" \) \
                -exec stat -f "%m %z %N" {} \; 2>/dev/null \
                | sort | ${pkgs.coreutils}/bin/sha256sum | cut -d' ' -f1)
            else
              CURRENT_STATE="$PREV_STATE"
            fi

            # Content-aware refresh
            if [ "$CURRENT_STATE" != "$PREV_STATE" ]; then
              echo "Font changes detected, refreshing cache..."
              [ -d "$FONT_CACHE" ] && rm -rf "''${FONT_CACHE:?}"/*
              ${pkgs.fontconfig}/bin/fc-cache -rfv
              # Save both file hash and directory state for next run
              echo "$CURRENT_STATE" > "$STATE_FILE"
              echo "$DIR_STATE" >> "$STATE_FILE"
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

            # Log significant operations
            if [ $FONT_REFRESH -eq 1 ]; then
              echo "Font cache refresh completed successfully"
            fi
          '';
        }
      }/bin/font-cache-daemon";
      logBaseName = "${config.xdg.stateHome}/logs/xdg-cleanup";
    };
  };
}
