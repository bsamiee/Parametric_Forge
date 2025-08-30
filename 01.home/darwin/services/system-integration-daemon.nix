# Title         : system-integration-daemon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/system-integration-daemon.nix
# ----------------------------------------------------------------------------
# System integration daemon for app quarantine removal and LaunchServices management.

{
  config,
  pkgs,
  myLib,
  context,
  userServiceHelpers,
  ...
}:

let
  # --- Service Helper Functions ---------------------------------------------
  inherit (userServiceHelpers) mkPeriodicJob;
  # --- Universal Service Environment ----------------------------------------
  serviceEnv = myLib.mkServiceEnvironment { inherit config context; };

  # --- App Quarantine Removal Script ---------------------------------------
  quarantineRemovalScript = pkgs.writeShellApplication {
    name = "quarantine-removal";
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "[$(date)] Starting application quarantine removal..."

      # State file to track processed apps
      STATE_DIR="${config.xdg.stateHome}/quarantine-state"
      PROCESSED_APPS="$STATE_DIR/quarantine-processed"
      mkdir -p "$STATE_DIR"

      # Function to remove quarantine with state tracking
      remove_quarantine() {
        local app_path="$1"
        
        if [[ -d "$app_path" ]]; then
          app_name=$(basename "$app_path")
          app_mtime=$(stat -f "%m" "$app_path" 2>/dev/null || echo "0")
          
          # Check if already processed and unchanged
          if grep -q "^$app_name:$app_mtime$" "$PROCESSED_APPS" 2>/dev/null; then
            return 0  # Skip already processed apps
          fi
          
          echo "  Processing: $app_name"
          
          # Check current quarantine status
          if xattr -l "$app_path" 2>/dev/null | grep -q quarantine; then
            echo "    [FOUND] Quarantine detected, removing..."
            
            # Remove quarantine from main app bundle
            if xattr -rd com.apple.quarantine "$app_path" 2>/dev/null; then
              echo "    [OK] Main bundle quarantine removed"
            else
              echo "    [WARN] Failed to remove main quarantine: $app_path"
              return 1
            fi
            
            # Remove quarantine from ALL nested bundles (comprehensive)
            find "$app_path" -name "*.app" -exec xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
            find "$app_path" -name "*.framework" -exec xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
            find "$app_path" -name "*.bundle" -exec xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
            find "$app_path" -name "*.dylib" -exec xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
            find "$app_path" -name "*.plugin" -exec xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
            
            # Verify complete removal
            if ! xattr -l "$app_path" 2>/dev/null | grep -q quarantine; then
              echo "    [SUCCESS] All quarantine attributes removed from $app_name"
              QUARANTINE_REMOVED=$((QUARANTINE_REMOVED + 1))
            else
              echo "    [ERROR] Some quarantine attributes remain in $app_name"
              return 1
            fi
          fi
          
          # Mark as processed
          echo "$app_name:$app_mtime" >> "$PROCESSED_APPS"
          PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
        fi
        return 0
      }

      PROCESSED_COUNT=0
      QUARANTINE_REMOVED=0

      # Process ALL applications in /Applications
      if [[ -d "/Applications" ]]; then
        echo "  [PROCESSING] Scanning /Applications directory..."
        while IFS= read -r -d $'\0' app; do
          remove_quarantine "$app" || true  # Continue even if one app fails
        done < <(find /Applications -maxdepth 1 -name "*.app" -type d -print0 2>/dev/null)
      fi

      # Process user applications if they exist
      if [[ -d "${context.userHome}/Applications" ]]; then
        echo "  [PROCESSING] Scanning user Applications directory..."
        while IFS= read -r -d $'\0' app; do
          remove_quarantine "$app" || true
        done < <(find "${context.userHome}/Applications" -maxdepth 1 -name "*.app" -type d -print0 2>/dev/null)
      fi

      # Process Nix Apps if they exist
      if [[ -d "/Applications/Nix Apps" ]]; then
        echo "  [PROCESSING] Scanning Nix Apps directory..."
        while IFS= read -r -d $'\0' app; do
          remove_quarantine "$app" || true
        done < <(find "/Applications/Nix Apps" -maxdepth 1 -name "*.app" -type d -print0 2>/dev/null)
      fi

      echo "[SUMMARY] Quarantine Removal Complete:"
      echo "  • Apps processed: $PROCESSED_COUNT"
      echo "  • Quarantine removed: $QUARANTINE_REMOVED"

      # Refresh LaunchServices if quarantine was removed
      if [ $QUARANTINE_REMOVED -gt 0 ]; then
        echo "  Refreshing LaunchServices database..."
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
          -kill -r -domain local -domain system -domain user 2>/dev/null || true
        echo "  [OK] LaunchServices database refreshed"
      fi
    '';
  };
in
{
  # --- Application Quarantine Removal Agent --------------------------------
  launchd.agents.app-quarantine-removal = {
    enable = true;
    config = mkPeriodicJob {
      label = "App Quarantine Removal";
      command = "${quarantineRemovalScript}/bin/quarantine-removal";
      interval = 43200; # Every 12 hours
      runAtLoad = true; # Run once at login
      nice = 15; # Lower priority
      logBaseName = "${config.xdg.stateHome}/logs/quarantine-removal";
      environmentVariables = serviceEnv;
    };
  };
}