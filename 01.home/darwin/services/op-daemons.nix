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

  # --- Enhanced Cache Manager Script (Authentication Delegated) -------------
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

      # Check if authenticated (no signin prompt - rely on coordinator)
      echo "[op-cache] Checking 1Password authentication status..."
      
      # Test authentication without triggering signin prompt
      if ! op account list >/dev/null 2>&1; then
        echo "[op-cache] Not authenticated - waiting for coordinator service"
        exit 0
      fi
      
      echo "[op-cache] Authentication confirmed via coordinator"

      # Check if template exists
      if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "[op-cache] No template file found at $TEMPLATE_FILE"
        exit 0
      fi

      # Create cache directory
      mkdir -p "$(dirname "$CACHE_FILE")"

      echo "[op-cache] Refreshing secret cache..."

      SUCCESS_COUNT=0
      FAIL_COUNT=0

      # Generate cache file with resolved secrets - with retry logic
      {
        echo "# 1Password secrets cache - Generated $(date)"
        echo "# DO NOT COMMIT THIS FILE"
        while IFS='=' read -r key value; do
          # Skip comments and empty lines
          [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

          # Try to resolve the secret with retries
          resolved=""
          for attempt in 1 2 3; do
            if resolved=$(op read "$value" 2>/dev/null); then
              break
            else
              [ $attempt -lt 3 ] && sleep 1
            fi
          done
          
          if [ -n "$resolved" ]; then
            echo "export $key='$resolved'"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
          else
            echo "# Failed to resolve: $key (after 3 attempts)"
            FAIL_COUNT=$((FAIL_COUNT + 1))
          fi
        done < "$TEMPLATE_FILE"
      } > "$CACHE_FILE.tmp"

      # Atomic move
      mv "$CACHE_FILE.tmp" "$CACHE_FILE"
      chmod 600 "$CACHE_FILE"

      # Send notification with better status
      if [ $FAIL_COUNT -eq 0 ]; then
        echo "[op-cache] ✓ Cache refreshed successfully: $SUCCESS_COUNT secrets cached"
      else
        echo "[op-cache] ⚠ Cache refresh completed with errors: $SUCCESS_COUNT cached, $FAIL_COUNT failed"
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
      if (${myLib.secrets.checkCacheFresh config.secrets.paths.cache 1440}); then
        source "${config.secrets.paths.cache}" 2>/dev/null || true
      fi

      # Helper to refresh cache manually - ONLY command that requires biometric auth
      op-refresh() {
        echo "Refreshing 1Password secrets cache (requires biometric auth)..."
        echo "This is the ONLY command that should prompt for authentication."
        if (${myLib.secrets.opAuthenticated}); then
          launchctl kickstart -k gui/$(id -u)/com.parametricforge.op-cache-manager
          echo "Cache refresh triggered - valid for 24 hours"
          echo "All other 1Password operations will use cache until next refresh needed"
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
          if (${myLib.secrets.checkCacheFresh config.secrets.paths.cache 1440}); then
            echo "  [OK] Cache is fresh (<24 hours)"
          else
            echo "  [WARN] Cache is stale (>24 hours)"
          fi
        else
          echo "  [ERROR] No cache file"
        fi
      }
    fi
  '';

  # --- Authentication Coordinator (Single Authentication Point) -------------
  authCoordinator = pkgs.writeShellApplication {
    name = "op-auth-coordinator";
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      echo "[op-auth] Starting 1Password authentication coordinator..."

      # Check if op CLI is available
      if ! command -v op >/dev/null 2>&1; then
        echo "[op-auth] 1Password CLI not found"
        exit 0
      fi

      # Check if already authenticated
      if op account list >/dev/null 2>&1; then
        echo "[op-auth] Already authenticated - triggering dependent services"
      else
        echo "[op-auth] Authenticating with 1Password (biometric prompt expected)..."
        # This is the ONLY place that should call op signin
        if ! op signin >/dev/null 2>&1; then
          echo "[op-auth] Authentication failed - services will retry later"
          exit 0
        fi
        echo "[op-auth] ✓ Authentication successful"
      fi

      # Trigger dependent services with delay to ensure auth propagation
      sleep 2
      echo "[op-auth] Triggering cache manager..."
      launchctl kickstart -k "gui/$(id -u)/com.parametricforge.op-cache-manager" 2>/dev/null || true
      
      sleep 1  
      echo "[op-auth] Triggering SSH setup..."
      launchctl kickstart -k "gui/$(id -u)/com.parametricforge.op-ssh-setup" 2>/dev/null || true
      
      echo "[op-auth] ✓ Coordinator completed successfully"
    '';
  };
in
{
  # --- Authentication Coordinator Agent (Runs First) -----------------------
  launchd.agents.onepassword-auth-coordinator = {
    enable = true;
    config = mkPeriodicJob {
      label = "1Password Authentication Coordinator";
      command = "${authCoordinator}/bin/op-auth-coordinator";
      interval = 86400; # Every 24 hours  
      runAtLoad = true;
      nice = 5; # Higher priority than dependent services
      logBaseName = "${config.xdg.stateHome}/logs/op-auth-coordinator";
      environmentVariables = serviceEnv // {
        OP_CACHE = "true";
        OP_ACCOUNT = "";
      };
    };
  };

  # --- Enhanced Cache Manager Agent (Authentication Delegated) -------------
  launchd.agents.onepassword-secrets = {
    enable = true;
    config = mkPeriodicJob {
      label = "Security Daemon";
      command = "${opCacheManager}/bin/security-daemon";
      interval = 86400; # Every 24 hours
      runAtLoad = false;  # Triggered by coordinator, not at boot
      nice = 15;  # Lower priority than coordinator
      logBaseName = "${config.xdg.stateHome}/logs/op-cache";
      environmentVariables = serviceEnv // {
        # Enable 1Password CLI caching to reduce auth prompts
        OP_CACHE = "true";
        # Set account context for CLI operations
        OP_ACCOUNT = "";
      };
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

            # Check if op CLI is available
            if ! command -v op >/dev/null 2>&1; then
              echo "[WARN] 1Password CLI not found"
              exit 0
            fi

            # Check if authenticated (no signin prompt - rely on coordinator) 
            if ! op account list >/dev/null 2>&1; then
              echo "[SKIP] Not authenticated - waiting for coordinator service"
              exit 0
            fi

            echo "[OK] Authentication confirmed via coordinator"

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
      interval = 86400; # Every 24 hours
      runAtLoad = false;  # Triggered by coordinator, not at boot
      nice = 15;  # Lower priority than coordinator
      logBaseName = "${config.xdg.stateHome}/logs/op-ssh-setup";
      environmentVariables = serviceEnv // {
        # Enable 1Password CLI caching
        OP_CACHE = "true";
        # Set account context for CLI operations  
        OP_ACCOUNT = "";
      };
    };
  };

  # --- Shell Integration ----------------------------------------------------
  programs.zsh.initContent = shellIntegration;
  programs.bash.initExtra = shellIntegration;
}
