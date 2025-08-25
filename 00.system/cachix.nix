# Title         : 00.system/cachix.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /00.system/cachix.nix
# ----------------------------------------------------------------------------
# Cachix post-build hook for automatic cache pushing.

{
  pkgs,
  ...
}:

let
  # --- Post-Build Hook ------------------------------------------------------
  cachixPostBuildHook = pkgs.writeScript "cachix-post-build-hook" ''
    #!${pkgs.runtimeShell}
    set -euf -o pipefail

    # Get cache name from environment or use default
    CACHE_NAME="''${CACHIX_CACHE:-bsamiee}"

    # Check if we have output paths to push
    if [ -z "''${OUT_PATHS:-}" ]; then
      exit 0
    fi

    # Only proceed if we have an auth token from environment
    if [ -n "''${CACHIX_AUTH_TOKEN:-}" ]; then
      # Count paths being pushed for visibility
      PATH_COUNT=$(echo "$OUT_PATHS" | tr ' ' '\n' | wc -l | tr -d ' ')
      echo "[Cachix] Pushing $PATH_COUNT paths to cache: $CACHE_NAME"

      echo "$OUT_PATHS" | ${pkgs.cachix}/bin/cachix push "$CACHE_NAME" 2>&1 || {
        echo "[Cachix] Push failed, but build succeeded"
        exit 0
      }
      echo "[Cachix] Successfully pushed $PATH_COUNT paths to $CACHE_NAME"
    else
      echo "[Cachix] No auth token available, skipping push"
      echo "[Cachix] Set CACHIX_AUTH_TOKEN environment variable to enable"
    fi
  '';
in
{
  # --- Enable Post-Build Hook -----------------------------------------------
  nix.settings = {
    # This runs after successful builds when CACHIX_AUTH_TOKEN is available
    # Set CACHIX_CACHE to override default cache name (defaults to bsamiee)
    post-build-hook = cachixPostBuildHook;
  };
}
