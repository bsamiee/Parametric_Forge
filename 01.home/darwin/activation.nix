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
    # --- File Association Management ----------------------------------------
    dutiFileAssociations = lib.hm.dag.entryAfter [ "xdgMigration" ] ''
      export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

      echo "[Parametric Forge] Applying file associations..."

      if command -v duti >/dev/null 2>&1; then
        if duti "${config.xdg.configHome}/duti/associations" 2>/dev/null; then
          echo "  [OK] File associations configured"
        else
          echo "  [WARN] Some associations may have failed"
        fi
      else
        echo "  [SKIP] duti not available"
      fi
    '';
    # --- Smart Mac App Store Management ------------------------------------
    smartMasInstall = lib.hm.dag.entryAfter [ "dutiFileAssociations" ] ''
      # Ensure homebrew PATH is available for mas CLI
      export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

      echo "[Parametric Forge] Smart Mac App Store management..."

      if command -v mas >/dev/null 2>&1; then
        # Check if user is signed into App Store (Sequoia-compatible)
        if ! mas list >/dev/null 2>&1 || [ -z "$(mas list 2>/dev/null)" ]; then
          echo "  [SKIP] Not signed into Mac App Store"
          echo "  [INFO] Sign in via System Settings > Apple ID or run 'mas signin'"
        else
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
            ["MEGAVPN"]="6456784858"
          )

          INSTALLED_IDS=$(mas list 2>/dev/null | awk '{print $1}' || echo "")
          OUTDATED_IDS=$(mas outdated 2>/dev/null | awk '{print $1}' || echo "")

          INSTALL_COUNT=0
          UPDATE_COUNT=0
          CURRENT_COUNT=0
          FAIL_COUNT=0

          for app_name in "''${!MAS_APPS[@]}"; do
            app_id="''${MAS_APPS[$app_name]}"

            if echo "$INSTALLED_IDS" | grep -q "^$app_id$"; then
              if echo "$OUTDATED_IDS" | grep -q "^$app_id$"; then
                echo "  [UPDATE] Updating: $app_name"
                if mas upgrade "$app_id" 2>/dev/null; then
                  UPDATE_COUNT=$((UPDATE_COUNT + 1))
                else
                  echo "  [WARN] Update failed: $app_name"
                  FAIL_COUNT=$((FAIL_COUNT + 1))
                fi
              else
                CURRENT_COUNT=$((CURRENT_COUNT + 1))
              fi
            else
              echo "  [INSTALL] Installing: $app_name"
              if mas install "$app_id" 2>/dev/null; then
                INSTALL_COUNT=$((INSTALL_COUNT + 1))
              else
                echo "  [WARN] Install failed: $app_name"
                FAIL_COUNT=$((FAIL_COUNT + 1))
              fi
            fi
          done

          if [ $((INSTALL_COUNT + UPDATE_COUNT)) -gt 0 ]; then
            echo "  [SUMMARY] MAS: $INSTALL_COUNT installed, $UPDATE_COUNT updated"
          fi
          [ $CURRENT_COUNT -gt 0 ] && echo "  [OK] $CURRENT_COUNT apps current"
          [ $FAIL_COUNT -gt 0 ] && echo "  [WARN] $FAIL_COUNT operations failed"
        fi
      else
        echo "  [SKIP] mas CLI not found"
      fi
    '';

    # --- Comprehensive User-Level Spotlight Protection ---------------------
    spotlightShield = lib.hm.dag.entryAfter [ "dutiFileAssociations" ] ''
      export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

      echo "[Parametric Forge] Deploying comprehensive user-level Spotlight protection..."

      # State tracking for protected directories
      PROTECTED_STATE="${config.xdg.stateHome}/spotlight-protected"
      mkdir -p "$(dirname "$PROTECTED_STATE")"
      : > "$PROTECTED_STATE" 2>/dev/null || true
      PROTECTED_STATE_TMP="$(mktemp -t pf-spotlight-protected.XXXXXX)"

      # Function: Deploy triple-layer exclusion to directory with state tracking
      shield_directory() {
        local dir="$1"
        local name="$(basename "$dir")"

        if [ -d "$dir" ]; then
          local dir_mtime
          dir_mtime=$(stat -f "%m" "$dir" 2>/dev/null || echo "0")

          # If unchanged, record state and signal skip via exit 2
          if grep -q "^$dir:$dir_mtime$" "$PROTECTED_STATE" 2>/dev/null; then
            echo "$dir:$dir_mtime" >> "$PROTECTED_STATE_TMP"
            return 2
          fi

          # Layer 1: Modern Spotlight exclusion (macOS 10.4+)
          touch "$dir/.metadata_never_index" 2>/dev/null || true
          # Layer 2: Legacy Spotlight exclusion (backward compatibility)
          touch "$dir/.noindex" 2>/dev/null || true
          # Layer 3: iCloud exclusion (prevents sync cascade)
          touch "$dir/.nosync" 2>/dev/null || true

          echo "  [OK] Protected: $name"

          # Record updated state
          echo "$dir:$dir_mtime" >> "$PROTECTED_STATE_TMP"
          return 0
        fi
        return 1
      }

      # Application Support directories - UNBLOCKED for Raycast functionality
      # Note: This may cause some browser indexing overhead but needed for search
      echo "  [PHASE 1] Skipping Application Support protection for search functionality..."
      APP_SUPPORT_PROTECTED=0
      # Commented out: Application Support blanket protection
      # if [ -d "$HOME/Library/Application Support" ]; then
      #   while IFS= read -r -d $'\0' dir; do
      #     if shield_directory "$dir"; then
      #       ((APP_SUPPORT_PROTECTED++))
      #     fi
      #   done < <(find "$HOME/Library/Application Support" -maxdepth 1 -type d ! -name "Application Support" -print0 2>/dev/null)
      # fi

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
        "$HOME/.venv"
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

      # Arc browser directories (CRITICAL for searchpartyd performance)
      ARC_DIRS=(
        "$HOME/Library/Application Support/Arc"
        "$HOME/Library/Caches/company.thebrowser.Browser"
        "$HOME/Library/WebKit/company.thebrowser.Browser"
        "$HOME/Library/HTTPStorages/company.thebrowser.Browser"
        "$HOME/Library/Saved Application State/company.thebrowser.Browser.savedState"
      )

      # PHASE 2: Arc browser directories (highest priority for searchpartyd fix)
      echo "  [PHASE 2] Protecting Arc browser directories (searchpartyd performance fix)..."
      ARC_PROTECTED=0
      for dir in "''${ARC_DIRS[@]}"; do
        shield_directory "$dir" && ((ARC_PROTECTED++)) || true
      done

      # PHASE 3: Development directories
      echo "  [PHASE 3] Protecting development and build caches..."
      DEV_PROTECTED=0
      for dir in "''${DEV_DIRS[@]}"; do
        shield_directory "$dir" && ((DEV_PROTECTED++)) || true
      done

      # PHASE 4: Cloud sync directories
      echo "  [PHASE 4] Protecting cloud sync directories..."
      CLOUD_PROTECTED=0
      for dir in "''${CLOUD_DIRS[@]}"; do
        shield_directory "$dir" && ((CLOUD_PROTECTED++)) || true
      done

      # PHASE 5: Dynamic project exclusions (optimized single traversal)
      echo "  [PHASE 5] Protecting dynamic project caches..."
      PYTHON_CACHE_COUNT=0
      NODE_MODULES_COUNT=0

      # Single find command with multiple conditions (3x faster)
      while IFS= read -r -d $'\0' dir; do
        case "$(basename "$dir")" in
          .venv|__pycache__|*.egg-info|.pytest_cache)
            shield_directory "$dir" && ((PYTHON_CACHE_COUNT++)) || true
            ;;
          node_modules)
            shield_directory "$dir" && ((NODE_MODULES_COUNT++)) || true
            ;;
        esac
      done < <(find "$HOME/Documents/99.Github" -maxdepth 4 -type d \( \
        -name ".venv" -o -name "__pycache__" -o -name "*.egg-info" -o -name ".pytest_cache" -o \
        -name "node_modules" \
      \) -print0 2>/dev/null)

      # Write consolidated state (replaces previous, bounds growth)
      if [ -s "$PROTECTED_STATE_TMP" ]; then
        mv "$PROTECTED_STATE_TMP" "$PROTECTED_STATE"
      else
        rm -f "$PROTECTED_STATE_TMP"
      fi

      # Summary with actual counts (newly protected only)
      echo "  [SUMMARY] Protection deployed:"
      echo "    • Application Support directories: $APP_SUPPORT_PROTECTED"
      echo "    • Arc browser directories: $ARC_PROTECTED (searchpartyd fix)"
      echo "    • Development caches: $DEV_PROTECTED"
      echo "    • Cloud sync folders: $CLOUD_PROTECTED"
      echo "    • Python caches: $PYTHON_CACHE_COUNT"
      echo "    • Node modules: $NODE_MODULES_COUNT"

      # Only log if meaningful work was done
      TOTAL_PROTECTED=$((APP_SUPPORT_PROTECTED + ARC_PROTECTED + DEV_PROTECTED + CLOUD_PROTECTED + PYTHON_CACHE_COUNT + NODE_MODULES_COUNT))
      if [ $TOTAL_PROTECTED -gt 0 ]; then
        echo "  [SUCCESS] $TOTAL_PROTECTED directories newly protected"
      else
        echo "  [OK] All directories already protected (state-managed)"
      fi
    '';

    # --- Karabiner Configuration Deployment --------------------------------
    karabinerDeployment = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "[Parametric Forge] Deploying Karabiner configuration files..."

      # Ensure directory exists
      mkdir -p "$HOME/.config/karabiner"

      SOURCE_JSON="${config.home.homeDirectory}/Documents/99.Github/Parametric_Forge/01.home/00.core/configs/apps/karabiner/karabiner.json"
      SOURCE_EDN="${config.home.homeDirectory}/Documents/99.Github/Parametric_Forge/01.home/00.core/configs/apps/karabiner/karabiner.edn"
      TARGET_JSON="$HOME/.config/karabiner/karabiner.json"
      TARGET_EDN="$HOME/.config/karabiner/karabiner.edn"

      if command -v goku >/dev/null 2>&1; then
        # Prefer EDN + Goku as source-of-truth
        rm -f "$TARGET_EDN" "$TARGET_EDN.backup"
        if [ -f "$SOURCE_EDN" ]; then
          cp "$SOURCE_EDN" "$TARGET_EDN"
          chmod 644 "$TARGET_EDN"
          echo "  ✓ karabiner.edn deployed with write permissions"
          export GOKU_EDN_CONFIG_FILE="$TARGET_EDN"
          if goku 2>/dev/null; then
            echo "  ✓ Goku compilation successful"
          else
            echo "  [WARN] Goku compilation failed (may need manual intervention)"
          fi
        else
          echo "  [WARN] Source karabiner.edn not found: $SOURCE_EDN"
        fi
      else
        # Fallback to static karabiner.json when Goku is unavailable
        rm -f "$TARGET_JSON" "$TARGET_JSON.backup"
        if [ -f "$SOURCE_JSON" ]; then
          cp "$SOURCE_JSON" "$TARGET_JSON"
          chmod 644 "$TARGET_JSON"
          echo "  ✓ karabiner.json deployed with write permissions"
        else
          echo "  [WARN] Source karabiner.json not found: $SOURCE_JSON"
        fi
      fi

      echo "[Parametric Forge] Karabiner deployment complete"
    '';

    # --- Hammerspoon init.lua Deployment -----------------------------------
    hammerspoonInitDeployment = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "[Parametric Forge] Deploying Hammerspoon init.lua..."

      # Ensure directory exists
      HS_DIR="${config.home.homeDirectory}/.hammerspoon"
      mkdir -p "$HS_DIR"

      # Deploy init.lua (writable copy)
      SOURCE_INIT="${config.home.homeDirectory}/Documents/99.Github/Parametric_Forge/01.home/00.core/configs/apps/hammerspoon/init.lua"
      TARGET_INIT="$HS_DIR/init.lua"

      # Remove any existing files (no backups)
      rm -f "$TARGET_INIT"
      rm -f "$TARGET_INIT.backup"

      # Copy with proper permissions
      if [ -f "$SOURCE_INIT" ]; then
        cp "$SOURCE_INIT" "$TARGET_INIT"
        chmod 644 "$TARGET_INIT"
        echo "  ✓ init.lua deployed with write permissions"
      else
        echo "  [WARN] Source init.lua not found: $SOURCE_INIT"
      fi

      echo "[Parametric Forge] Hammerspoon init.lua deployment complete"
    '';

    # --- Hammerspoon Forge/Assets Deployment -------------------------------
    hammerspoonForgeDeployment = lib.hm.dag.entryAfter [ "hammerspoonInitDeployment" ] ''
      echo "[Parametric Forge] Deploying Hammerspoon forge modules and assets..."

      HS_DIR="${config.home.homeDirectory}/.hammerspoon"
      SRC_BASE="${config.home.homeDirectory}/Documents/99.Github/Parametric_Forge/01.home/00.core/configs/apps/hammerspoon"

      mkdir -p "$HS_DIR/forge" "$HS_DIR/assets"

      # Copy forge modules (overwrite with writable files) — include all Lua modules
      for src in "$SRC_BASE"/forge/*.lua; do
        [ -f "$src" ] || continue
        f="$(basename "$src")"
        cp "$src" "$HS_DIR/forge/$f"
        chmod 644 "$HS_DIR/forge/$f"
      done

      # Copy assets directory (images for menubar)
      if [ -d "$SRC_BASE/assets" ]; then
        if command -v rsync >/dev/null 2>&1; then
          rsync -a --delete "$SRC_BASE/assets/" "$HS_DIR/assets/"
        else
          # Fallback to cp -R if rsync is unavailable
          rm -rf "$HS_DIR/assets"/*
          cp -R "$SRC_BASE/assets/." "$HS_DIR/assets/"
        fi
      fi

      echo "[Parametric Forge] Hammerspoon forge/assets deployment complete"
    '';

    # --- Karabiner assets (complex modifications) --------------------------
    karabinerAssetsDeployment = lib.hm.dag.entryAfter [ "karabinerDeployment" ] ''
      echo "[Parametric Forge] Deploying Karabiner complex modifications..."
      SRC_JSON="${config.home.homeDirectory}/Documents/99.Github/Parametric_Forge/01.home/00.core/configs/apps/karabiner/assets/complex_modifications/parametric-forge.json"
      DEST_DIR="${config.xdg.configHome}/karabiner/assets/complex_modifications"
      mkdir -p "$DEST_DIR"
      if [ -f "$SRC_JSON" ]; then
        cp "$SRC_JSON" "$DEST_DIR/parametric-forge.json"
        chmod 644 "$DEST_DIR/parametric-forge.json"
        echo "  ✓ Karabiner complex modifications deployed"
      else
        echo "  [WARN] Source complex modifications not found"
      fi
    '';
  };
}
