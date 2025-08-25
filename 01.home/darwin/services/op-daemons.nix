# Title         : 01.home/darwin/services/op-daemons.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/darwin/services/op-daemons.nix
# ----------------------------------------------------------------------------
# macOS launchd agent for 1Password CLI integration and cache management.

{
  config,
  pkgs,
  myLib,
  context,
  userServiceHelpers,
  ...
}:

let
  # --- Service Helper Functions ---------------------------------------------
  inherit (userServiceHelpers) mkPeriodicJob;
  # --- Common launchd PATH Environment --------------------------------------
  launchdPath = "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin";

  # --- Combined Cache Manager Script ----------------------------------------
  opCacheManager = pkgs.writeShellScript "op-cache-manager" ''
    #!/usr/bin/env bash
    set -euo pipefail

    CACHE_FILE="${config.secrets.paths.cache}"
    TEMPLATE_FILE="${config.secrets.paths.template}"

    # Check if op CLI is available
    if ! command -v op >/dev/null 2>&1; then
      echo "[op-cache] 1Password CLI not found"
      exit 0
    fi

    # Check authentication
    if ! op account get >/dev/null 2>&1; then
      echo "[op-cache] Not authenticated to 1Password"
      exit 0
    fi

    echo "[op-cache] Connected to 1Password"

    # Check if template exists
    if [ ! -f "$TEMPLATE_FILE" ]; then
      echo "[op-cache] No template file found"
      exit 0
    fi

    # Create cache directory
    mkdir -p "$(dirname "$CACHE_FILE")"

    echo "[op-cache] Refreshing secret cache..."

    # Generate cache file with resolved secrets
    {
      echo "# 1Password secrets cache - Generated $(date)"
      echo "# DO NOT COMMIT THIS FILE"
      while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

        # Try to resolve the secret
        if resolved=$(op read "$value" 2>/dev/null); then
          echo "export $key='$resolved'"
        else
          echo "# Failed to resolve: $key"
        fi
      done < "$TEMPLATE_FILE"
    } > "$CACHE_FILE.tmp"

    # Atomic move
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    chmod 600 "$CACHE_FILE"

    echo "[op-cache] Cache refreshed successfully"
  '';

  # --- Shell Integration Script (shared between bash and zsh) ---------------
  shellIntegration = ''
    # 1Password CLI integration
    if (${myLib.secrets.opAvailable}); then
      # Helper function to run commands with secrets
      op-run() {
        if [ -f "${config.secrets.paths.template}" ]; then
          op run --env-file="${config.secrets.paths.template}" -- "$@"
        else
          echo "No secrets template found. Running command directly."
          "$@"
        fi
      }

      # Load cached secrets if available (for non-sensitive operations)
      if (${myLib.secrets.checkCacheFresh config.secrets.paths.cache 60}); then
        source "${config.secrets.paths.cache}" 2>/dev/null || true
      fi

      # Helper to refresh cache manually
      op-refresh() {
        echo "Refreshing 1Password secrets cache..."
        if (${myLib.secrets.opAuthenticated}); then
          launchctl kickstart -k gui/$(id -u)/com.parametricforge.op-cache-manager
          echo "Cache refresh triggered"
        else
          echo "Not authenticated. Run: op signin"
        fi
      }

      # Status check helper
      op-status() {
        echo "1Password Integration Status:"
        if (${myLib.secrets.opAvailable}); then
          echo "  ✓ CLI installed"
        else
          echo "  ✗ CLI not found"
        fi

        if (${myLib.secrets.opAuthenticated}); then
          echo "  ✓ Authenticated"
        else
          echo "  ✗ Not authenticated"
        fi

        if [ -S "${myLib.secrets.opSSHSocket context}" ]; then
          echo "  ✓ SSH agent socket exists"
        else
          echo "  ✗ SSH agent socket not found"
        fi

        if [ -f "${config.secrets.paths.cache}" ]; then
          echo "  ✓ Cache file exists"
          if (${myLib.secrets.checkCacheFresh config.secrets.paths.cache 60}); then
            echo "  ✓ Cache is fresh (<60 minutes)"
          else
            echo "  ⚠ Cache is stale (>60 minutes)"
          fi
        else
          echo "  ✗ No cache file"
        fi
      }
    fi
  '';
in
{
  # --- Unified Cache Manager Agent ------------------------------------------
  launchd.agents.op-cache-manager = mkPeriodicJob {
    command = "${opCacheManager}";
    interval = 3600; # Every hour
    runAtLoad = true;
    nice = 10;
    logBaseName = "${config.xdg.stateHome}/op-cache";
    environmentVariables = {
      PATH = launchdPath;
      HOME = config.home.homeDirectory;
    };
    # Additional config that mkPeriodicJob passes through
    WatchPaths = [
      config.secrets.paths.template
    ];
  };

  # --- Shell Integration ----------------------------------------------------
  programs.zsh.initContent = shellIntegration;
  programs.bash.initExtra = shellIntegration;
}
