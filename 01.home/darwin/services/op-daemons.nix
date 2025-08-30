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
  lib,
  ...
}:

let
  # --- Service Helper Functions ---------------------------------------------
  inherit (userServiceHelpers) mkPeriodicJob;
  # --- Universal Service Environment ----------------------------------------
  serviceEnv = myLib.mkServiceEnvironment { inherit config context; };

  # --- Combined Cache Manager Script ----------------------------------------
  opCacheManager = pkgs.writeShellApplication {
    name = "security-daemon";
    text = ''
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

      SUCCESS_COUNT=0
      FAIL_COUNT=0

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
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
          else
            echo "# Failed to resolve: $key"
            FAIL_COUNT=$((FAIL_COUNT + 1))
          fi
        done < "$TEMPLATE_FILE"
      } > "$CACHE_FILE.tmp"

      # Atomic move
      mv "$CACHE_FILE.tmp" "$CACHE_FILE"
      chmod 600 "$CACHE_FILE"

      # Send notification
      if [ $FAIL_COUNT -eq 0 ]; then
        echo "[op-cache] Cache refreshed successfully: $SUCCESS_COUNT secrets cached"
      else
        echo "[op-cache] Cache refresh completed with errors: $SUCCESS_COUNT cached, $FAIL_COUNT failed"
      fi
    '';
  };

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
          echo "  [OK] CLI installed"
        else
          echo "  [ERROR] CLI not found"
        fi

        if (${myLib.secrets.opAuthenticated}); then
          echo "  [OK] Authenticated"
        else
          echo "  [ERROR] Not authenticated"
        fi

        if [ -S "${myLib.secrets.opSSHSocket context}" ]; then
          echo "  [OK] SSH agent socket exists"
        else
          echo "  [ERROR] SSH agent socket not found"
        fi

        if [ -f "${config.secrets.paths.cache}" ]; then
          echo "  [OK] Cache file exists"
          if (${myLib.secrets.checkCacheFresh config.secrets.paths.cache 60}); then
            echo "  [OK] Cache is fresh (<60 minutes)"
          else
            echo "  [WARN] Cache is stale (>60 minutes)"
          fi
        else
          echo "  [ERROR] No cache file"
        fi
      }
    fi
  '';
in
{
  # --- Unified Cache Manager Agent ------------------------------------------
  launchd.agents.onepassword-secrets = {
    enable = true;
    config = mkPeriodicJob {
      label = "Security Daemon";
      command = "${opCacheManager}/bin/security-daemon";
      interval = 3600; # Every hour
      runAtLoad = true;
      nice = 10;
      logBaseName = "${config.xdg.stateHome}/op-cache";
      environmentVariables = serviceEnv;
      # Additional config that mkPeriodicJob passes through
      WatchPaths = [
        config.secrets.paths.template
      ];
    };
  };

  # --- SSH Key Management Agent --------------------------------------------
  launchd.agents.onepassword-ssh-setup = {
    enable = true;
    config = mkPeriodicJob {
      label = "1Password SSH Setup";
      command = "${
        pkgs.writeShellApplication {
          name = "op-ssh-setup";
          text = ''
            #!/usr/bin/env bash
            set -euo pipefail

            echo "[$(date)] Starting 1Password SSH key setup..."

            # Check if op CLI is available and authenticated
            if ! command -v op >/dev/null 2>&1; then
              echo "[WARN] 1Password CLI not found"
              exit 0
            fi

            if ! op account get >/dev/null 2>&1; then
              echo "[WARN] Not authenticated to 1Password"
              exit 0
            fi

            echo "[OK] 1Password CLI available and authenticated"

            # Ensure SSH directory exists
            mkdir -p ~/.ssh
            chmod 700 ~/.ssh

            SUCCESS_COUNT=0
            FAIL_COUNT=0

            ${lib.optionalString (config.secrets.references ? sshAuthKey && config.secrets.references ? sshSigningKey) ''
              # Fetch authentication key with validation
              echo "Fetching SSH authentication key..."
              if AUTH_KEY=$(op read "${config.secrets.references.sshAuthKey}" 2>/dev/null) && [[ "$AUTH_KEY" == ssh-* ]]; then
                echo "$AUTH_KEY" > ~/.ssh/github_auth.pub
                chmod 644 ~/.ssh/github_auth.pub
                echo "[OK] Authentication key saved"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
              else
                echo "[WARN] Failed to fetch valid authentication key"
                rm -f ~/.ssh/github_auth.pub
                FAIL_COUNT=$((FAIL_COUNT + 1))
              fi

              # Fetch signing key with validation
              echo "Fetching SSH signing key..."
              if SIGN_KEY=$(op read "${config.secrets.references.sshSigningKey}" 2>/dev/null) && [[ "$SIGN_KEY" == ssh-* ]]; then
                echo "$SIGN_KEY" > ~/.ssh/github_sign.pub
                chmod 644 ~/.ssh/github_sign.pub
                echo "[OK] Signing key saved"

                # Update allowed_signers
                EMAIL=$(git config --global user.email 2>/dev/null || echo "${config.home.username}@users.noreply.github.com")
                echo "$EMAIL $SIGN_KEY" > ~/.ssh/allowed_signers
                chmod 644 ~/.ssh/allowed_signers
                echo "[OK] Allowed signers updated"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
              else
                echo "[WARN] Failed to fetch valid signing key"
                rm -f ~/.ssh/github_sign.pub ~/.ssh/allowed_signers
                FAIL_COUNT=$((FAIL_COUNT + 1))
              fi
            ''}

            # Configure gh CLI with 1Password plugin
            echo "Configuring gh CLI with 1Password..."
            if command -v op-gh-setup.sh >/dev/null 2>&1; then
              if op-gh-setup.sh >/dev/null 2>&1; then
                echo "[OK] gh CLI configured with 1Password"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
              else
                echo "[WARN] gh CLI configuration failed"
                FAIL_COUNT=$((FAIL_COUNT + 1))
              fi
            else
              echo "[WARN] op-gh-setup.sh not found in PATH"
              FAIL_COUNT=$((FAIL_COUNT + 1))
            fi

            echo "[SUMMARY] SSH Setup Complete: $SUCCESS_COUNT successful, $FAIL_COUNT failed"
          '';
        }
      }/bin/op-ssh-setup";
      interval = 21600; # Every 6 hours
      runAtLoad = true;
      nice = 10;
      logBaseName = "${config.xdg.stateHome}/logs/op-ssh-setup";
      environmentVariables = serviceEnv;
    };
  };

  # --- Shell Integration ----------------------------------------------------
  programs.zsh.initContent = shellIntegration;
  programs.bash.initExtra = shellIntegration;
}
