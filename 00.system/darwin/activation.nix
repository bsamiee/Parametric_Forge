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
    # --- Enhanced App Permission Management ---------------------------------
    appPermissionManagement = {
      text = ''
        echo "[Parametric Forge] Enhanced app permissions management..."

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

        # State file to track processed apps
        STATE_DIR="/var/tmp/parametric-forge"
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
              
              # Remove quarantine from main app bundle with sudo
              if sudo xattr -rd com.apple.quarantine "$app_path" 2>/dev/null; then
                echo "    [OK] Main bundle quarantine removed"
              else
                echo "    [WARN] Failed to remove main quarantine: $app_path"
                return 1
              fi
              
              # Remove quarantine from ALL nested bundles (comprehensive)
              find "$app_path" -name "*.app" -exec sudo xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
              find "$app_path" -name "*.framework" -exec sudo xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
              find "$app_path" -name "*.bundle" -exec sudo xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
              find "$app_path" -name "*.dylib" -exec sudo xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
              find "$app_path" -name "*.plugin" -exec sudo xattr -rd com.apple.quarantine {} \; 2>/dev/null || true
              
              # Verify complete removal
              if ! xattr -l "$app_path" 2>/dev/null | grep -q quarantine; then
                echo "    [SUCCESS] All quarantine attributes removed from $app_name"
              else
                echo "    [ERROR] Some quarantine attributes remain in $app_name"
                return 1
              fi
            fi
            
            # Mark as processed
            echo "$app_name:$app_mtime" >> "$PROCESSED_APPS"
          fi
        }

        # Process ALL applications in /Applications
        echo "  [PROCESSING] Scanning /Applications directory..."
        find /Applications -maxdepth 1 -name "*.app" -type d | while read -r app; do
          remove_quarantine "$app"
        done

        # Process user applications if they exist
        if [[ -d "${context.userHome}/Applications" ]]; then
          echo "  [PROCESSING] Scanning user Applications directory..."
          find "${context.userHome}/Applications" -maxdepth 1 -name "*.app" -type d | while read -r app; do
            remove_quarantine "$app"
          done
        fi

        # Process Nix Apps if they exist
        if [[ -d "/Applications/Nix Apps" ]]; then
          echo "  [PROCESSING] Scanning Nix Apps directory..."
          find "/Applications/Nix Apps" -maxdepth 1 -name "*.app" -type d | while read -r app; do
            remove_quarantine "$app"
          done
        fi

        # Additional security bypass optimizations
        echo "  [OPTIMIZATION] Applying additional security bypasses..."

        # Clear system security caches
        sudo killall -HUP mDNSResponder 2>/dev/null || true
        sudo dscacheutil -flushcache 2>/dev/null || true

        # Clear Launch Services database to remove stale quarantine references
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
          -kill -r -domain local -domain system -domain user 2>/dev/null || true

        echo "  [COMPLETE] Enhanced app permission management finished"
        echo "  [NOTE] Apps should now launch significantly faster without security delays"
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
      deps = [ "appPermissionManagement" ];
    };
    # --- Default Browser Setup ---------------------------------------------
    defaultBrowserSetup = {
      text = ''
        echo "[Parametric Forge] Setting Arc as default browser..."

        if command -v defaultbrowser >/dev/null 2>&1; then
          if defaultbrowser browser 2>/dev/null; then
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
    # --- Yabai Passwordless Sudo Setup -------------------------------------
    yabaiSudoSetup = {
      text = ''
        echo "[Parametric Forge] Configuring passwordless sudo for yabai..."

        YABAI_PATH=$(command -v yabai || echo "/opt/homebrew/bin/yabai")
        if [ -x "$YABAI_PATH" ]; then
          YABAI_SHA=$(shasum -a 256 "$YABAI_PATH" | cut -d " " -f 1)
          SUDOERS_CONTENT="${context.user} ALL=(root) NOPASSWD: sha256:$YABAI_SHA $YABAI_PATH --load-sa"
          
          echo "$SUDOERS_CONTENT" > /tmp/yabai_sudoers
          
          if sudo visudo -cf /tmp/yabai_sudoers; then
            sudo cp /tmp/yabai_sudoers /private/etc/sudoers.d/yabai
            sudo chmod 440 /private/etc/sudoers.d/yabai
            echo "  [OK] Passwordless sudo configured for yabai scripting addition"
          else
            echo "  [ERROR] sudoers syntax error - manual configuration required"
          fi
          rm -f /tmp/yabai_sudoers
        else
          echo "  [WARN] yabai binary not found at expected location"
        fi
      '';
      deps = [ "defaultBrowserSetup" ];
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
