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
    # --- Nix Store Exclusions -----------------------------------------------
    nixStoreExclusions = {
      text = ''
        echo "[Parametric Forge] Excluding Nix store from indexing/backup..."

        # Exclude Nix store from Spotlight
        if [ -d "/nix" ]; then
          mdutil -i off -d /nix 2>/dev/null || true
          touch /nix/.metadata_never_index 2>/dev/null || true
          echo "  ✓ Spotlight excluded: /nix store"
        fi

        # Exclude Nix store from Time Machine
        if [ -d "/nix" ]; then
          tmutil addexclusion /nix 2>/dev/null || true
          echo "  ✓ Time Machine excluded: /nix store"
        fi

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

        # Force LaunchServices database rebuild
        echo "  Rebuilding LaunchServices database..."
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
          -kill -r -domain local -domain system -domain user 2>/dev/null || true
        echo "  ✓ LaunchServices database rebuilt"
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
