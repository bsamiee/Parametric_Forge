# Title         : 00.system/darwin/activation.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/darwin/activation.nix
# ----------------------------------------------------------------------------
# System activation scripts and environment setup for Darwin.

{ context, ... }:
{
  # --- System Activation Scripts --------------------------------------------
  system.activationScripts = {
    # --- Parametric Forge Banner --------------------------------------------
    parametricForge = {
      text = ''
        echo ""
        echo "╔══════════════════════════════════════════════════════════════════════╗"
        echo "║                      Parametric Forge Activation                     ║"
        echo "╚══════════════════════════════════════════════════════════════════════╝"
        echo "  Platform: macOS (${context.arch})"
        echo "  User: ${context.user}"
        echo "  Home: ${context.userHome}"
        echo "  Config: ${context.configName}"
        echo "════════════════════════════════════════════════════════════════════════"
        echo ""
      '';
      deps = [ ];
    };
    # --- Performance Optimizations ------------------------------------------
    performanceOptimizations = {
      text = ''
        echo "[Parametric Forge] Applying performance optimizations..."

        # Proven mdutil exclusions (nix-darwin community approach)
        if [ -d "/nix" ]; then
          sudo mdutil -i off /nix 2>/dev/null && echo "  [OK] Disabled Spotlight indexing: /nix"
          sudo tmutil addexclusion /nix 2>/dev/null && echo "  [OK] Time Machine excluded: /nix"
        fi

        # Cloud storage exclusions (if not manually added to Privacy)
        CLOUD_DIR="${context.userHome}/Library/CloudStorage"
        if [ -d "$CLOUD_DIR" ]; then
          sudo mdutil -i off "$CLOUD_DIR" 2>/dev/null && echo "  [OK] Disabled Spotlight indexing: CloudStorage"
          sudo tmutil addexclusion "$CLOUD_DIR" 2>/dev/null && echo "  [OK] Time Machine excluded: CloudStorage"
        fi

        # Cache directories exclusions
        CACHE_DIRS=(
          "${context.userHome}/Library/Caches"
          "${context.userHome}/.cache" 
        )
        for dir in "''${CACHE_DIRS[@]}"; do
          if [ -d "$dir" ]; then
            sudo mdutil -i off "$dir" 2>/dev/null && echo "  [OK] Disabled Spotlight indexing: $(basename "$dir")"
          fi
        done

        # Note: Process throttling removed to prevent potential EPERM errors during build

        echo "  [INFO] For optimal performance, also add folders manually to:"
        echo "    System Settings > Spotlight > Search Privacy"

      '';
      deps = [ "etc" ];
    };
    # --- Nix Applications Integration ---------------------------------------
    nixAppsIntegration = {
      text = ''
        echo "[Parametric Forge] Setting up Nix applications integration..."

        APPS_DIR="/Applications/Nix Apps"
        mkdir -p "$APPS_DIR"

        # Clean up broken symlinks from previous generations
        echo "  Cleaning broken symlinks..."
        find "$APPS_DIR" -type l ! -exec test -e {} \; -delete 2>/dev/null || true

        # Link applications from user profile
        if [ -d "${context.userHome}/Applications" ]; then
          echo "  Linking applications from user profile..."
          for app in "${context.userHome}/Applications"/*.app;
          do
            if [ -e "$app" ]; then
              app_name=$(basename "$app")
              ln -sf "$app" "$APPS_DIR/$app_name"
              echo "  [OK] Linked: $app_name"
            fi
          done
        fi

        # Link applications from system profile
        if [ -d "/run/current-system/Applications" ]; then
          echo "  Linking applications from system profile..."
          for app in /run/current-system/Applications/*.app;
          do
            if [ -e "$app" ]; then
              app_name=$(basename "$app")
              if [ ! -e "$APPS_DIR/$app_name" ]; then
                ln -sf "$app" "$APPS_DIR/$app_name"
                echo "  [OK] Linked: $app_name"
              fi
            fi
          done
        fi

        # Minimal LaunchServices refresh (only if changes detected)
        if [ -n "$(find "$APPS_DIR" -newer "$APPS_DIR" -print -quit 2>/dev/null)" ]; then
          echo "  Changes detected, refreshing LaunchServices for Nix apps..."
          /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
            -f -R "$APPS_DIR" 2>/dev/null || true
          echo "  [OK] LaunchServices updated for new apps only"
        else
          echo "  [OK] No app changes detected, skipping LaunchServices refresh"
        fi
      '';
      deps = [
        "etc"
        "users"
      ];
    };
    # --- Darwin XDG Runtime Directory ---------------------------------------
    darwinRuntimeDirectory = {
      text = ''
        echo "[Parametric Forge] Ensuring XDG runtime directory exists..."

        RUNTIME_DIR="${context.userHome}/Library/Caches/TemporaryItems"

        # Create runtime directory with proper permissions
        if [ ! -d "$RUNTIME_DIR" ]; then
          mkdir -pm 700 "$RUNTIME_DIR"
          echo "  [OK] Created XDG runtime directory at $RUNTIME_DIR"
        else
          echo "  [OK] XDG runtime directory exists"
        fi
      '';
      deps = [ "users" ];
    };
    # --- App Permission Management ------------------------------------------
    appPermissionManagement = {
      text = ''
        echo "[Parametric Forge] Managing app permissions..."

        # Check Gatekeeper status (do not disable to preserve security)
        if spctl --status | grep -q "enabled"; then
          echo "  [INFO] Gatekeeper is enabled (recommended for security)"
          echo "  [INFO] Use 'spctl --master-disable' manually if needed"
        else
          echo "  [WARN] Gatekeeper is disabled"
        fi

        # Remove quarantine from common problematic apps
        find /Applications -maxdepth 2 -name "*.app" -exec xattr -rd com.apple.quarantine {} \; 2>/dev/null || true

        # Remove quarantine from user Applications
        if [ -d "${context.userHome}/Applications" ]; then
          find "${context.userHome}/Applications" -maxdepth 2 -name "*.app" -exec xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
        fi

        echo "  [OK] Removed quarantine from all applications"
      '';
      deps = [ "nixAppsIntegration" ];
    };
    # --- Sequoia FileProvider Performance Fixes ---------------------------
    sequoiaFixes = {
      text = ''
        echo "[Parametric Forge] Applying targeted Sequoia fixes..."

        # Clear FileProvider caches only (preserve system services)
        rm -rf "${context.userHome}/Library/Caches/com.apple.FileProvider"* 2>/dev/null || true
        echo "  [OK] FileProvider caches cleared"

        # Exclude sync folders from Spotlight (preserve system folders)
        SYNC_FOLDERS=(
          "${context.userHome}/Google Drive"
          "${context.userHome}/OneDrive" 
          "${context.userHome}/Dropbox"
          "${context.userHome}/MEGAsync"
        )

        for folder in "''${SYNC_FOLDERS[@]}"; do
          if [ -d "$folder" ]; then
            mdutil -i off "$folder" 2>/dev/null && echo "  [OK] Spotlight excluded: $(basename "$folder")"
          fi
        done

        echo "  [OK] Targeted Sequoia fixes applied (system services preserved)"
      '';
      deps = [ "performanceOptimizations" ];
    };
    # --- Smart Mac App Store Management ------------------------------------
    smartMasInstall = {
      text = ''
        echo "[Parametric Forge] Smart Mac App Store management..."

        if ! command -v mas >/dev/null 2>&1; then
          echo "  [WARN] mas CLI not found, skipping App Store management"
          exit 0
        fi

        # App ID mappings (from original masApps)
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

        INSTALLED_IDS=$(mas list 2>/dev/null | awk '{print $1}' || echo "")
        OUTDATED_IDS=$(mas outdated 2>/dev/null | awk '{print $1}' || echo "")

        for app_name in "''${!MAS_APPS[@]}"; do
          app_id="''${MAS_APPS[$app_name]}"
          
          if echo "$INSTALLED_IDS" | grep -q "^$app_id$"; then
            if echo "$OUTDATED_IDS" | grep -q "^$app_id$"; then
              echo "  [UPDATE] Updating: $app_name"
              mas upgrade "$app_id" 2>/dev/null || echo "  [WARN] Update failed: $app_name"
            else
              echo "  [OK] Current: $app_name"
            fi
          else
            echo "  [INSTALL] Installing: $app_name"
            mas install "$app_id" 2>/dev/null || echo "  [WARN] Install failed: $app_name"
          fi
        done

        echo "  [OK] Mac App Store management completed"
      '';
      deps = [ "sequoiaFixes" ];
    };
    # --- Default Browser Setup ---------------------------------------------
    defaultBrowserSetup = {
      text = ''
        echo "[Parametric Forge] Setting Arc as default browser..."

        if command -v defaultbrowser >/dev/null 2>&1; then
          if defaultbrowser arc 2>/dev/null; then
            echo "  [OK] Arc set as default browser"
          else
            echo "  [WARN] Failed to set Arc as default"
          fi
        else
          echo "  [WARN] defaultbrowser tool not available yet (installing via Homebrew)"
        fi
      '';
      deps = [ "smartMasInstall" ];
    };
  };
  # --- Shell Initialization -------------------------------------------------
  environment.shellInit = ''
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  '';
}
