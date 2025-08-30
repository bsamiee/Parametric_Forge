# Title         : app-management-daemon.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/app-management-daemon.nix
# ----------------------------------------------------------------------------
# Mac App Store and application management daemon.

{
  config,
  pkgs,
  myLib,
  userServiceHelpers,
  ...
}:

let
  # --- Service Helper Functions ---------------------------------------------
  inherit (userServiceHelpers) mkPeriodicJob;

  # --- Mac App Store Management Script -------------------------------------
  masManagerScript = pkgs.writeShellApplication {
    name = "mas-manager";
    runtimeInputs = [ pkgs.mas ];
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "[$(date)] Starting Mac App Store management..."

      # Check if mas CLI is available
      if ! command -v mas >/dev/null 2>&1; then
        echo "[WARN] mas CLI not found, skipping App Store management"
        exit 0
      fi

      # App ID mappings
      declare -A MAS_APPS=(
        ["Microsoft Excel"]="462058435"
        ["Microsoft PowerPoint"]="462062816" 
        ["Microsoft Word"]="462054704"
        ["OneDrive"]="823766827"
        ["Drafts"]="1435957248"
        ["Fantastical"]="975937182"
        ["Goodnotes"]="1444383602"
        ["CARROT Weather"]="993487541"
        ["CleanMyMac"]="1339170533"
        ["Icon Tool for Developers"]="554660130"
        ["Keka"]="470158793"
        ["Parcel"]="639968404"
        ["Rapidmg"]="6451349778"
        ["MEGAVPN"]="6456784858"
      )

      # Get installed and outdated app IDs
      INSTALLED_IDS=$(mas list 2>/dev/null | awk '{print $1}' || echo "")
      OUTDATED_IDS=$(mas outdated 2>/dev/null | awk '{print $1}' || echo "")

      INSTALL_COUNT=0
      UPDATE_COUNT=0
      CURRENT_COUNT=0
      FAIL_COUNT=0

      # Process each app
      for app_name in "''${!MAS_APPS[@]}"; do
        app_id="''${MAS_APPS[$app_name]}"
        
        if echo "$INSTALLED_IDS" | grep -q "^$app_id$"; then
          if echo "$OUTDATED_IDS" | grep -q "^$app_id$"; then
            echo "[UPDATE] Updating: $app_name"
            if mas upgrade "$app_id" 2>/dev/null; then
              UPDATE_COUNT=$((UPDATE_COUNT + 1))
            else
              echo "[WARN] Update failed: $app_name"
              FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
          else
            echo "[OK] Current: $app_name"
            CURRENT_COUNT=$((CURRENT_COUNT + 1))
          fi
        else
          echo "[INSTALL] Installing: $app_name"
          if mas install "$app_id" 2>/dev/null; then
            INSTALL_COUNT=$((INSTALL_COUNT + 1))
          else
            echo "[WARN] Install failed: $app_name"
            FAIL_COUNT=$((FAIL_COUNT + 1))
          fi
        fi
      done

      # Summary
      echo "[SUMMARY] MAS Management Complete:"
      echo "  • Apps current: $CURRENT_COUNT"
      echo "  • Apps installed: $INSTALL_COUNT"
      echo "  • Apps updated: $UPDATE_COUNT"
      echo "  • Failed operations: $FAIL_COUNT"
    '';
  };

  # --- Default Browser Setup Script ----------------------------------------
  browserSetupScript = pkgs.writeShellApplication {
    name = "browser-setup";
    runtimeInputs = [ pkgs.defaultbrowser ];
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "[$(date)] Setting up default browser..."

      # Check if defaultbrowser tool is available
      if ! command -v defaultbrowser >/dev/null 2>&1; then
        echo "[WARN] defaultbrowser tool not found, skipping browser setup"
        exit 0
      fi

      # Attempt to set Arc as default browser
      if defaultbrowser browser 2>/dev/null; then
        echo "[OK] Arc set as default browser"
      else
        echo "[WARN] Failed to set Arc as default browser"
        # Try to get current default for troubleshooting
        current_browser=$(defaultbrowser 2>/dev/null || echo "unknown")
        echo "[INFO] Current default browser: $current_browser"
      fi
    '';
  };
in
{
  # --- Mac App Store Management Agent --------------------------------------
  launchd.agents.app-store-manager = {
    enable = true;
    config = mkPeriodicJob {
      label = "MAS Daemon";
      command = "${masManagerScript}/bin/mas-manager";
      interval = 86400; # Daily
      runAtLoad = false; # Don't run immediately, wait for system to settle
      nice = 10;
      logBaseName = "${config.xdg.stateHome}/logs/mas-manager";
    };
  };

  # --- Default Browser Setup Agent -----------------------------------------
  launchd.agents.browser-setup = {
    enable = true;
    config = mkPeriodicJob {
      label = "Browser Setup Daemon";
      command = "${browserSetupScript}/bin/browser-setup";
      interval = 604800; # Weekly
      runAtLoad = true; # Run once at login
      nice = 10;
      logBaseName = "${config.xdg.stateHome}/logs/browser-setup";
    };
  };
}