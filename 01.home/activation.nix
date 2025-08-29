# Title         : 01.home/activation.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/activation.nix
# ----------------------------------------------------------------------------
# Home activation scripts for 1Password secrets and XDG template generation.

{
  config,
  lib,
  myLib,
  context,
  pkgs,
  ...
}:

{
  # --- Home Activation Scripts ----------------------------------------------
  home.activation = {
    # --- Yazi Plugin Installation --------------------------------------------
    yaziPlugins = lib.hm.dag.entryAfter [ "createXdgDirs" ] ''
      # Auto-install/update Yazi plugins when package.toml changes
      YAZI_CONFIG="${config.xdg.configHome}/yazi/package.toml"
      YAZI_CACHE="${config.xdg.cacheHome}/yazi/plugins.sha256"

      # Calculate current package.toml checksum
      CURRENT_HASH=$(shasum -a 256 "$YAZI_CONFIG" | cut -d' ' -f1)
      CACHED_HASH=$(cat "$YAZI_CACHE" 2>/dev/null || echo "")

      # Install/update plugins only if package.toml changed
      if [ "$CURRENT_HASH" != "$CACHED_HASH" ]; then
        echo "[Yazi] Synchronizing plugins..."

        # Install/update all plugins from package.toml
        if ya pack -i >/dev/null 2>&1; then
          echo "    [OK] Yazi plugins updated"
          echo "$CURRENT_HASH" > "$YAZI_CACHE"
        else
          echo "    [WARN] Some plugins failed to install"
        fi
      fi
    '';

    # --- Alerter Installation ------------------------------------------------
    alerterSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "$HOME/.local/bin/alerter" ]; then
        echo "[Alerter] Installing notification tool..."
        ${lib.optionalString context.isDarwin ''
          mkdir -p "$HOME/.local/bin"
          if command -v curl >/dev/null 2>&1; then
            curl -sL "https://github.com/vjeantet/alerter/releases/download/1.0.1/alerter_v1.0.1_darwin_amd64.zip" \
              -o /tmp/alerter.zip && \
            unzip -q /tmp/alerter.zip -d /tmp && \
            mv /tmp/alerter "$HOME/.local/bin/alerter" && \
            chmod +x "$HOME/.local/bin/alerter" && \
            rm -f /tmp/alerter.zip && \
            echo "    [OK] Alerter installed"
          else
            echo "    [WARN] curl not available - alerter installation skipped"
          fi
        ''}
      fi
    '';

    # --- SQLite Extensions Setup --------------------------------------------
    sqliteExtensions = lib.hm.dag.entryAfter [ "createXdgDirs" ] ''
      # Install sqlean (not in nixpkgs)
      if [ ! -f "$HOME/.local/lib/sqlean/uuid.dylib" ]; then
        echo "[SQLite] Installing sqlean extensions..."
        ${lib.optionalString context.isDarwin ''
          ARCH=$([ "$(uname -m)" = "arm64" ] && echo "aarch64" || echo "x86_64")
          curl -sL "https://github.com/nalgeon/sqlean/releases/latest/download/sqlean-macos-$ARCH.zip" \
            | tar -xz -C "$HOME/.local/lib/sqlean" --strip-components=0 2>/dev/null || echo "  [WARN] Manual install required"
        ''}
      fi
      # Link sqlite-vec (from nixpkgs)
      mkdir -p "$HOME/.local/lib/sqlite-vec"
      if [ -f "${pkgs.sqlite-vec}/lib/vec0.dylib" ]; then
        ln -sf "${pkgs.sqlite-vec}/lib/vec0.dylib" "$HOME/.local/lib/sqlite-vec/vec0.dylib"
        echo "    [OK] sqlite-vec linked from Nix store"
      elif [ -f "${pkgs.sqlite-vec}/lib/sqlite-vec.dylib" ]; then
        ln -sf "${pkgs.sqlite-vec}/lib/sqlite-vec.dylib" "$HOME/.local/lib/sqlite-vec/vec0.dylib"
        echo "    [OK] sqlite-vec linked from Nix store (alternative name)"
      else
        echo "    [WARN] sqlite-vec not found in expected locations"
      fi
      # Link libspatialite
      ln -sf "${pkgs.libspatialite}/lib/mod_spatialite.dylib" "$HOME/.local/lib/mod_spatialite.dylib" 2>/dev/null || true
    '';

    # --- Consolidated 1Password Setup ---------------------------------------
    opSetup = lib.hm.dag.entryAfter [ "sqliteExtensions" ] ''
      echo "[1Password] Initializing secrets and SSH..."

      # Check CLI availability and authentication
      if (${myLib.secrets.opAvailable}); then
        echo "  [OK] CLI found"
        if (${myLib.secrets.opAuthenticated}); then
          echo "  [OK] Authenticated"
        else
          echo "  [WARN] Not authenticated - run 'op signin'"
        fi
      else
        echo "  [WARN] CLI not found - install with: brew install 1password-cli"
      fi

      # Check SSH agent socket
      SOCKET_PATH="${myLib.secrets.opSSHSocket context}"
      if [ -z "$SOCKET_PATH" ]; then
        echo "  [WARN] Unknown platform - SSH agent path not configured"
      elif [ -S "$SOCKET_PATH" ]; then
        echo "  [OK] SSH agent at: $SOCKET_PATH"
      else
        echo "  [WARN] SSH agent not running at: $SOCKET_PATH"
        ${lib.optionalString context.isDarwin ''
          echo "    Enable in 1Password app: Settings → Developer → SSH Agent"
        ''}
        ${lib.optionalString context.isLinux ''
          echo "    Ensure 1Password 8.10.28+ is installed with SSH agent enabled"
        ''}
        ${lib.optionalString (context.isWSL or false) ''
          echo "    For WSL: Configure npiperelay bridge or set WSL_1PASSWORD_SOCKET"
        ''}
      fi

      ${lib.optionalString (config.secrets.references ? sshAuthKey && config.secrets.references ? sshSigningKey) ''
        if ${myLib.secrets.opReady}; then
          echo "  Fetching SSH keys..."

          # Fetch authentication key with validation
          AUTH_KEY=$(${myLib.secrets.fetchSecret config.secrets.references.sshAuthKey})
          if [ -n "$AUTH_KEY" ] && [[ "$AUTH_KEY" == ssh-* ]]; then
            echo "$AUTH_KEY" > ~/.ssh/github_auth.pub
            chmod 644 ~/.ssh/github_auth.pub
            echo "    [OK] Authentication key saved"
          else
            echo "    [WARN] Failed to fetch valid authentication key"
            rm -f ~/.ssh/github_auth.pub
          fi

          # Fetch signing key with validation
          SIGN_KEY=$(${myLib.secrets.fetchSecret config.secrets.references.sshSigningKey})
          if [ -n "$SIGN_KEY" ] && [[ "$SIGN_KEY" == ssh-* ]]; then
            echo "$SIGN_KEY" > ~/.ssh/github_sign.pub
            chmod 644 ~/.ssh/github_sign.pub
            echo "    [OK] Signing key saved"

            # Update allowed_signers
            EMAIL=$(git config --global user.email 2>/dev/null || echo "${config.home.username}@users.noreply.github.com")
            echo "$EMAIL $SIGN_KEY" > ~/.ssh/allowed_signers
            chmod 644 ~/.ssh/allowed_signers
            echo "    [OK] Allowed signers updated"
          else
            echo "    [WARN] Failed to fetch valid signing key"
            rm -f ~/.ssh/github_sign.pub ~/.ssh/allowed_signers
          fi
        else
          echo "  [WARN] Cannot fetch SSH keys - 1Password not ready"
          echo "    Run 'op signin' and then 'home-manager switch' to retry"
        fi
      ''}

      # Configure gh CLI with 1Password plugin
      echo "  Configuring gh CLI with 1Password..."
      if ${myLib.secrets.opReady}; then
        if command -v op-gh-setup.sh >/dev/null 2>&1; then
          op-gh-setup.sh >/dev/null 2>&1 && echo "    [OK] gh CLI configured with 1Password" || echo "    [WARN] gh CLI configuration failed"
        else
          echo "    [WARN] op-gh-setup.sh not found in PATH (will be available after deployment)"
        fi
      else
        echo "    [WARN] Skipping gh CLI setup - 1Password not ready"
      fi
    '';

  };
  # --- XDG Config Files -----------------------------------------------------
  xdg.configFile."op/env.template" = {
    text = ''
      # 1Password Secret References Template
      # Generated by Parametric Forge
      # Use with: op run --env-file=~/.config/op/env.template -- <command>

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: ref: "${name}=${ref}") config.secrets.environment)}
    '';
    onChange = ''
      echo "[Parametric Forge] Updated 1Password environment template"
      echo "  Location: ${config.secrets.paths.template}"
      echo "  Secrets configured: ${toString (builtins.length (builtins.attrNames config.secrets.environment))}"
    '';
  };

}
