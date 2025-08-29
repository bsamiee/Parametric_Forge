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
          sudo mdutil -i off /nix 2>/dev/null && echo "  ✓ Disabled Spotlight indexing: /nix"
          sudo tmutil addexclusion /nix 2>/dev/null && echo "  ✓ Time Machine excluded: /nix"
        fi

        # Cloud storage exclusions (if not manually added to Privacy)
        CLOUD_DIR="${context.userHome}/Library/CloudStorage"
        if [ -d "$CLOUD_DIR" ]; then
          sudo mdutil -i off "$CLOUD_DIR" 2>/dev/null && echo "  ✓ Disabled Spotlight indexing: CloudStorage"
          sudo tmutil addexclusion "$CLOUD_DIR" 2>/dev/null && echo "  ✓ Time Machine excluded: CloudStorage"
        fi

        # Cache directories exclusions
        CACHE_DIRS=(
          "${context.userHome}/Library/Caches"
          "${context.userHome}/.cache" 
        )
        for dir in "''${CACHE_DIRS[@]}"; do
          if [ -d "$dir" ]; then
            sudo mdutil -i off "$dir" 2>/dev/null && echo "  ✓ Disabled Spotlight indexing: $(basename "$dir")"
          fi
        done

        # CoreDuet nuclear throttling (SIP prevents deletion, so throttle to death)
        for proc in contextstored coreduetd; do
          pid=$(pgrep "$proc" 2>/dev/null | head -1)
          if [ -n "$pid" ]; then
            sudo renice +19 "$pid" 2>/dev/null || true
            sudo taskpolicy -b -p "$pid" 2>/dev/null || true  
            sudo taskpolicy -c maintenance -p "$pid" 2>/dev/null || true
            echo "  ✓ Maximum throttled: $proc (E-cores only, maintenance QoS)"
          fi
        done

        echo "  ℹ For optimal performance, also add folders manually to:"
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
              echo "  ✓ Linked: $app_name"
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
                echo "  ✓ Linked: $app_name"
              fi
            fi
          done
        fi

        # Gentle LaunchServices refresh (preserve authentication)
        echo "  Refreshing LaunchServices for Nix apps only..."
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
          -f -R "$APPS_DIR" 2>/dev/null || true
        echo "  ✓ LaunchServices refreshed without breaking system auth"
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
          echo "  ✓ Created XDG runtime directory at $RUNTIME_DIR"
        else
          echo "  ✓ XDG runtime directory exists"
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
          echo "  ℹ Gatekeeper is enabled (recommended for security)"
          echo "  ℹ Use 'spctl --master-disable' manually if needed"
        else
          echo "  ⚠ Gatekeeper is disabled"
        fi

        # Remove quarantine from common problematic apps
        find /Applications -maxdepth 2 -name "*.app" -exec xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
        
        # Remove quarantine from user Applications
        if [ -d "${context.userHome}/Applications" ]; then
          find "${context.userHome}/Applications" -maxdepth 2 -name "*.app" -exec xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
        fi
        
        echo "  ✓ Removed quarantine from all applications"
      '';
      deps = [ "nixAppsIntegration" ];
    };
    # --- Sequoia FileProvider Performance Fixes ---------------------------
    sequoiaFixes = {
      text = ''
        echo "[Parametric Forge] Applying Sequoia FileProvider fixes..."
        
        # FileProvider nuclear option - disable broken extensions
        for ext in $(pluginkit -m -p com.apple.FileProvider 2>/dev/null | grep -o '[a-zA-Z0-9.-]*\.FileProvider[a-zA-Z0-9.-]*' || true); do
          pluginkit -r "$ext" 2>/dev/null || true
        done
        pkill -f fileproviderd 2>/dev/null || true
        echo "  ✓ FileProvider extensions reset"
        
        # Exclude problematic sync folders from Spotlight
        SYNC_FOLDERS=(
          "${context.userHome}/Library/CloudStorage"
          "${context.userHome}/Library/Application Support/CloudDocs" 
          "${context.userHome}/Google Drive"
          "${context.userHome}/OneDrive"
          "${context.userHome}/Dropbox"
          "${context.userHome}/MEGAsync"
        )
        
        for folder in "''${SYNC_FOLDERS[@]}"; do
          if [ -d "$folder" ]; then
            mdutil -i off "$folder" 2>/dev/null && echo "  ✓ Spotlight excluded: $(basename "$folder")"
          fi
        done
        
        # Clear FileProvider caches
        rm -rf "${context.userHome}/Library/Caches/com.apple.FileProvider"* 2>/dev/null || true
        
        # Throttle mdworker processes 
        for pid in $(pgrep mdworker 2>/dev/null || true); do
          renice +15 "$pid" 2>/dev/null || true
        done
        
        echo "  ✓ Sequoia performance fixes applied"
      '';
      deps = [ "performanceOptimizations" ];
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
