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
    # Nix app integration simplified - let nix-darwin handle app linking automatically
    # XDG runtime handled by system defaults - no manual setup needed
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
      deps = [ "systemSpotlightProtection" ];
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
      deps = [ "etc" ];
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
}
