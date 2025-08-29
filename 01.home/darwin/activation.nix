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
        echo "  ✓ Migrated git config (original preserved)"
      fi

      if [ -f "${config.home.homeDirectory}/.npmrc" ] && [ ! -f "${config.xdg.configHome}/npm/npmrc" ]; then
        echo "  → Migrating .npmrc to XDG location..."
        cp "${config.home.homeDirectory}/.npmrc" "${config.xdg.configHome}/npm/npmrc"
        echo "  ✓ Migrated npm config (original preserved)"
      fi
    '';
    # --- Exclusion Markers --------------------------------------------------
    exclusionMarkers = lib.hm.dag.entryAfter [ "xdgMigration" ] ''
      # Create exclusion markers in key directories
      for dir in Downloads Documents Projects Development Code repos workspace .config; do
        [ -d "$HOME/$dir" ] && { touch "$HOME/$dir"/{.metadata_never_index,.nosync,.noindex} 2>/dev/null; } || true
      done
      echo "[Parametric Forge] ✓ Exclusion markers deployed"
    '';
  };
}
