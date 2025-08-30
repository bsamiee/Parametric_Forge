# Title         : 01.home/darwin/activation.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/activation.nix
# ----------------------------------------------------------------------------
# macOS-specific user activation scripts and configuration migration.

{
  config,
  lib,
  ...
}:

{
  # --- Home Activation Scripts ----------------------------------------------
  home.activation = {
    # --- XDG Migration ------------------------------------------------------
    xdgMigration = lib.hm.dag.entryAfter [ "createXdgDirs" ] ''
      echo "[Parametric Forge] Checking for legacy configs to migrate..."

      if [ -f "${config.home.homeDirectory}/.gitconfig" ] && [ ! -f "${config.xdg.configHome}/git/config" ]; then
        echo "  → Migrating .gitconfig to XDG location..."
        cp "${config.home.homeDirectory}/.gitconfig" "${config.xdg.configHome}/git/config"
        echo "  [OK] Migrated git config (original preserved)"
      fi

      if [ -f "${config.home.homeDirectory}/.npmrc" ] && [ ! -f "${config.xdg.configHome}/npm/npmrc" ]; then
        echo "  → Migrating .npmrc to XDG location..."
        cp "${config.home.homeDirectory}/.npmrc" "${config.xdg.configHome}/npm/npmrc"
        echo "  [OK] Migrated npm config (original preserved)"
      fi
    '';
    # --- Comprehensive User-Level Spotlight Protection ---------------------
    spotlightShield = lib.hm.dag.entryAfter [ "xdgMigration" ] ''
      export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

      echo "[Parametric Forge] Deploying comprehensive user-level Spotlight protection..."

      # State tracking for protected directories
      PROTECTED_STATE="${config.xdg.stateHome}/spotlight-protected"
      mkdir -p "$(dirname "$PROTECTED_STATE")"

      # Function: Deploy triple-layer exclusion to directory with state tracking
      shield_directory() {
        local dir="$1"
        local name="$(basename "$dir")"

        if [ -d "$dir" ]; then
          local dir_mtime=$(stat -f "%m" "$dir" 2>/dev/null || echo "0")
          
          # Check if already protected and unchanged
          if grep -q "^$dir:$dir_mtime$" "$PROTECTED_STATE" 2>/dev/null; then
            return 0  # Skip already protected directories
          fi
          
          # Layer 1: Modern Spotlight exclusion (macOS 10.4+)
          touch "$dir/.metadata_never_index" 2>/dev/null || true
          # Layer 2: Legacy Spotlight exclusion (backward compatibility)
          touch "$dir/.noindex" 2>/dev/null || true
          # Layer 3: iCloud exclusion (prevents sync cascade)
          touch "$dir/.nosync" 2>/dev/null || true

          echo "  [OK] Protected: $name"
          
          # Mark as protected
          echo "$dir:$dir_mtime" >> "$PROTECTED_STATE"
          return 0
        fi
        return 1
      }

      # CRITICAL: All Application Support directories (browsers cause massive CPU usage)
      echo "  [PHASE 1] Protecting all browser and app data..."
      APP_SUPPORT_PROTECTED=0
      if [ -d "$HOME/Library/Application Support" ]; then
        while IFS= read -r -d $'\0' dir; do
          if shield_directory "$dir"; then
            ((APP_SUPPORT_PROTECTED++))
          fi
        done < <(find "$HOME/Library/Application Support" -maxdepth 1 -type d ! -name "Application Support" -print0 2>/dev/null)
      fi

      # Development and build directories
      DEV_DIRS=(
        "$HOME/.cache"
        "$HOME/.npm"
        "$HOME/.cargo"
        "$HOME/.rustup"
        "$HOME/.local/share/nvim"
        "$HOME/.config/nix"
        "$HOME/.nix-profile"
        "$HOME/Library/Developer"
        "$HOME/Library/Fonts"
        "$HOME/Documents/99.Github"
        "$HOME/.venv"
        "$HOME/illustrator-mcp-tmp"
        "$HOME/ladybug_tools"
      )

      # Cloud sync directories (prevent cascade at source)
      CLOUD_DIRS=(
        "$HOME/Google Drive"
        "$HOME/OneDrive"
        "$HOME/OneDrive - Mazan Group"
        "$HOME/b.samiee93@gmail.com - Google Drive"
        "$HOME/b.samiee@mzn-group.com - Google Drive"
        "$HOME/MEGAsync"
        "$HOME/Creative Cloud Files Personal Account b.samiee@mzn-group.com F8CF4DB961A518290A495CCB@AdobeID"
      )

      # PHASE 2: Development directories
      echo "  [PHASE 2] Protecting development and build caches..."
      DEV_PROTECTED=0
      for dir in "''${DEV_DIRS[@]}"; do
        shield_directory "$dir" && ((DEV_PROTECTED++)) || true
      done

      # PHASE 3: Cloud sync directories
      echo "  [PHASE 3] Protecting cloud sync directories..."
      CLOUD_PROTECTED=0
      for dir in "''${CLOUD_DIRS[@]}"; do
        shield_directory "$dir" && ((CLOUD_PROTECTED++)) || true
      done

      # PHASE 4: Dynamic project exclusions (optimized single traversal)
      echo "  [PHASE 4] Protecting dynamic project caches..."
      PYTHON_CACHE_COUNT=0
      NODE_MODULES_COUNT=0
      GIT_COUNT=0

      # Single find command with multiple conditions (3x faster)
      while IFS= read -r -d $'\0' dir; do
        case "$(basename "$dir")" in
          .venv|__pycache__|*.egg-info|.pytest_cache)
            shield_directory "$dir" && ((PYTHON_CACHE_COUNT++)) || true
            ;;
          node_modules)
            shield_directory "$dir" && ((NODE_MODULES_COUNT++)) || true
            ;;
          .git)
            shield_directory "$dir" && ((GIT_COUNT++)) || true
            ;;
        esac
      done < <(find "$HOME/Documents/99.Github" -maxdepth 4 -type d \( \
        -name ".venv" -o -name "__pycache__" -o -name "*.egg-info" -o -name ".pytest_cache" -o \
        -name "node_modules" -o -name ".git" \
      \) -print0 2>/dev/null)

      # Summary with actual counts
      echo "  [SUMMARY] Protection deployed:"
      echo "    • Application Support directories: $APP_SUPPORT_PROTECTED"
      echo "    • Development caches: $DEV_PROTECTED"
      echo "    • Cloud sync folders: $CLOUD_PROTECTED"  
      echo "    • Python caches: $PYTHON_CACHE_COUNT"
      echo "    • Node modules: $NODE_MODULES_COUNT"
      echo "    • Git repositories: $GIT_COUNT"
      
      # Only log if meaningful work was done
      TOTAL_PROTECTED=$((APP_SUPPORT_PROTECTED + DEV_PROTECTED + CLOUD_PROTECTED + PYTHON_CACHE_COUNT + NODE_MODULES_COUNT + GIT_COUNT))
      if [ $TOTAL_PROTECTED -gt 0 ]; then
        echo "  [SUCCESS] $TOTAL_PROTECTED directories newly protected"
      else
        echo "  [OK] All directories already protected (state-managed)"
      fi
    '';
  };
}
