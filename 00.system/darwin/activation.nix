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
    # --- System-Level Spotlight Protection ----------------------------------
    systemSpotlightProtection = {
      text = ''
        # Simplified logging: 0=silent, 1=minimal, 2=verbose (default)  
        LOG_LEVEL=''${PARAMETRIC_FORGE_LOG_LEVEL:-2}

        [ "$LOG_LEVEL" -ge 1 ] && echo "[Parametric Forge] Applying system-level Spotlight protection..."

        # CRITICAL: System-wide directories requiring sudo access
        SYSTEM_EXCLUSIONS=(
          "/nix"                                    # Nix store (massive file count)
          "${context.userHome}/Library/CloudStorage" # Apple's cloud sync integration
          "${context.userHome}/Library/Caches"       # System-wide app caches
          "${context.userHome}/.cache"               # Unix-style cache directory
        )

        for dir in "''${SYSTEM_EXCLUSIONS[@]}"; do
          if [ -d "$dir" ]; then
            if sudo mdutil -i off "$dir" 2>/dev/null; then
              [ "$LOG_LEVEL" -ge 2 ] && echo "  [OK] System exclusion: $(basename "$dir")"
              # Also exclude from Time Machine for performance
              sudo tmutil addexclusion "$dir" 2>/dev/null || true
            else
              [ "$LOG_LEVEL" -ge 1 ] && echo "  [WARN] Failed to exclude: $dir"
            fi
          fi
        done

        [ "$LOG_LEVEL" -ge 1 ] && echo "  [INFO] System-level protection complete"
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

        # Use macOS default temporary directory structure
        RUNTIME_DIR=$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || echo "/tmp")

        # Ensure runtime directory exists with proper permissions
        if [ ! -d "$RUNTIME_DIR" ]; then
          mkdir -pm 700 "$RUNTIME_DIR"
          echo "  [OK] Created XDG runtime directory at $RUNTIME_DIR"
        else
          echo "  [OK] XDG runtime directory exists at $RUNTIME_DIR"
        fi
      '';
      deps = [ "users" ];
    };
    # --- Window Management Service Restart ----------------------------------
    restartWindowManagement = {
      text = ''
        echo "[Parametric Forge] Restarting window management services..."
        
        # Kill running services to force configuration reload
        /usr/bin/killall yabai 2>/dev/null || true
        /usr/bin/killall skhd 2>/dev/null || true  
        /usr/bin/killall sketchybar 2>/dev/null || true
        /usr/bin/killall borders 2>/dev/null || true
        
        sleep 2
        
        echo "  [OK] Services restarted - configurations will reload automatically"
      '';
      deps = [ "darwinRuntimeDirectory" ];
    };
    # --- Security Settings Optimization ------------------------------------
    securityOptimization = {
      text = ''
        echo "[Parametric Forge] Optimizing system security settings..."

        # CRITICAL: Disable Gatekeeper entirely for maximum performance
        echo "  [SECURITY] Disabling Gatekeeper for performance optimization..."

        # Method 1: Disable via defaults (works reliably)
        sudo defaults write /Library/Preferences/com.apple.security.assessment disable -bool true 2>/dev/null || true
        sudo defaults write /Library/Preferences/com.apple.security GKAutoRearm -bool false 2>/dev/null || true

        # Method 2: Fallback to spctl (may require System Settings confirmation)
        sudo spctl --global-disable 2>/dev/null || true

        # Verify status
        if spctl --status 2>&1 | grep -q "disabled"; then
          echo "  [OK] Gatekeeper disabled - no more security delays"
        else
          echo "  [WARN] Gatekeeper may still be enabled - check System Settings"
        fi

        # Clear system security caches
        sudo killall -HUP mDNSResponder 2>/dev/null || true
        sudo dscacheutil -flushcache 2>/dev/null || true

        # Clear Launch Services database to remove stale quarantine references
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
          -kill -r -domain local -domain system -domain user 2>/dev/null || true

        echo "  [OK] Security optimization complete"
      '';
      deps = [ "fileProviderOptimization" ];
    };
    # --- FileProvider Cache Management -------------------------------------
    fileProviderOptimization = {
      text = ''
        echo "[Parametric Forge] Optimizing FileProvider performance..."

        # Clear FileProvider caches that cause sync cascade issues
        rm -rf "${context.userHome}/Library/Caches/com.apple.FileProvider"* 2>/dev/null || true
        echo "  [OK] FileProvider caches cleared"

        echo "  [INFO] FileProvider optimization complete"
      '';
      deps = [ "systemSpotlightProtection" ];
    };
  };
  # --- Shell Initialization -------------------------------------------------
  environment.shellInit = ''
    # Homebrew integration
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  '';
  # --- Performance environment variables moved to 00.system/environment.nix
}
