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
    # --- Spotlight Exclusion & Cloud Sync Protection -------------------------
    spotlightShield = lib.hm.dag.entryAfter [ "xdgMigration" ] ''
      # Ensure full system PATH is available
      export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

      echo "[Parametric Forge] Deploying surgical Spotlight exclusions..."

      # Function: Deploy triple-layer exclusion to directory
      shield_directory() {
        local dir="$1"
        local name="$(basename "$dir")"

        if [ -d "$dir" ]; then
          # Layer 1: Modern Spotlight exclusion (primary)
          touch "$dir/.metadata_never_index" 2>/dev/null || true

          # Layer 2: Legacy Spotlight exclusion (compatibility)
          touch "$dir/.noindex" 2>/dev/null || true

          # Layer 3: iCloud exclusion (prevents iCloud sync cascade)
          touch "$dir/.nosync" 2>/dev/null || true

          echo "  [OK] Shielded: $name"
          return 0
        fi
        return 1
      }

      # High-impact development directories (cause massive cascade)
      DEV_DIRS=(
        "$HOME/.cache"
        "$HOME/.npm"
        "$HOME/.cargo"
        "$HOME/.rustup"
        "$HOME/.local/share/nvim"
        "$HOME/.config/nix"
        "$HOME/.nix-profile"
        "$HOME/Library/Caches"
        "$HOME/Library/Application Support/Code/CachedExtensions"
        "$HOME/Library/Application Support/Code/logs"
        "$HOME/Library/Developer"
        "$HOME/Library/Fonts"
        "$HOME/CZURImages"
        "$HOME/Heptabase-auto-backup"
        "$HOME/Downloads/00.Color theory and pallete related"
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

      # Shield development directories
      DEV_PROTECTED=0
      for dir in "''${DEV_DIRS[@]}"; do
        shield_directory "$dir" && ((DEV_PROTECTED++)) || true
      done

      # Shield cloud sync directories
      CLOUD_PROTECTED=0
      for dir in "''${CLOUD_DIRS[@]}"; do
        shield_directory "$dir" && ((CLOUD_PROTECTED++)) || true
      done

      # Python project exclusions (high-impact cache directories)
      PYTHON_CACHE_COUNT=0
      PYTHON_PATTERNS=(".venv" "__pycache__" ".pytest_cache" "*.egg-info" ".cache/nox")
      for pattern in "''${PYTHON_PATTERNS[@]}"; do
        if command -v find >/dev/null 2>&1; then
          while IFS= read -r -d $'\0' dir; do
            shield_directory "$dir" && ((PYTHON_CACHE_COUNT++)) || true
          done < <(find "$HOME/Documents/99.Github" -maxdepth 3 -type d -name "$pattern" -print0 2>/dev/null | head -5)
        fi
      done

      # Node.js cache directories (limit to prevent over-exclusion)
      NODE_MODULES_COUNT=0
      if command -v find >/dev/null 2>&1; then
        while IFS= read -r -d $'\0' dir; do
          shield_directory "$dir" && ((NODE_MODULES_COUNT++)) || true
        done < <(find "$HOME/Documents/99.Github" -type d -name "node_modules" -print0 2>/dev/null | head -15)
      fi

      # Git repositories (exclude .git directories only)
      GIT_COUNT=0
      if command -v find >/dev/null 2>&1; then
        while IFS= read -r -d $'\0' dir; do
          shield_directory "$dir" && ((GIT_COUNT++)) || true
        done < <(find "$HOME/Documents/99.Github" -type d -name ".git" -print0 2>/dev/null | head -20)
      fi

      # Nix store exclusion (if writable)
      NIX_PROTECTED=0
      for nix_path in "/nix/store" "$HOME/.nix-defexpr"; do
        shield_directory "$nix_path" && ((NIX_PROTECTED++)) || true
      done

      echo "  [OK] Development: $DEV_PROTECTED protected"
      echo "  [OK] Cloud sync: $CLOUD_PROTECTED protected"
      echo "  [OK] Python caches: $PYTHON_CACHE_COUNT protected"
      echo "  [OK] Node modules: $NODE_MODULES_COUNT protected"
      echo "  [OK] Git repos: $GIT_COUNT protected"
      echo "  [OK] Nix paths: $NIX_PROTECTED protected"
      echo "  [INFO] Spotlight cascade protection deployed - $(($DEV_PROTECTED + $CLOUD_PROTECTED + $PYTHON_CACHE_COUNT + $NODE_MODULES_COUNT + $GIT_COUNT + $NIX_PROTECTED)) total shields"
    '';
  };
}
