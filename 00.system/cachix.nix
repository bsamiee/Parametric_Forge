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

    CACHE_NAME="''${CACHIX_CACHE:-bsamiee}"

    if [ -z "''${OUT_PATHS:-}" ]; then
      exit 0
    fi

    if [ -n "''${CACHIX_AUTH_TOKEN:-}" ]; then
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
  # --- Nix Settings ---------------------------------------------------------
  nix.settings = {
    post-build-hook = cachixPostBuildHook;
  };
}
