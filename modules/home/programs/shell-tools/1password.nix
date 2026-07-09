# Title         : 1password.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/1password.nix
# ----------------------------------------------------------------------------
# 1Password: Shell Plugins (gh), biometric CLI auth, token injection on rebuild
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Cutover flip row (t5x's terminal act): "transition" keeps the 1Password
  # fallback lanes alive; "doppler" dispatches every lane to the doppler-first
  # session cache alone. One value flips CLI, TUI, and GUI at the next switch.
  secretBackend = "transition";
  sessionCache = "${config.xdg.cacheHome}/forge-secrets/session-env.sh";
  opCache = "${config.xdg.configHome}/hm-op-session.sh";
  replayConstants = [
    "CLAUDE_SECRET_BACKEND"
    "CLOUDSDK_CONFIG"
    "WORKSPACE_MCP_CREDENTIALS_DIR"
    "GOOGLE_WORKSPACE_CLI_CONFIG_DIR"
    "GOOGLE_WORKSPACE_PROJECT_ID"
    "MAGHZ_REMOTE_HOST"
    "MAGHZ_REMOTE_USER"
    "MAGHZ_REMOTE_WORKROOT"
  ];
  # GUI-session secret replay: source the backend-dispatched session material
  # and re-export each key into the launchd GUI domain via "launchctl setenv"
  # so GUI-launched apps (Codex.app, Claude Desktop) inherit the same tokens
  # as interactive shells. Key NAMES are enumerated from both caches; a name
  # whose backend leaves it unset is skipped, so the flip narrows this replay.
  guiOpSecrets = pkgs.writeShellApplication {
    name = "gui-op-secrets";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep pkgs.gawk];
    text = ''
      # shellcheck source=/dev/null
      [ ! -f "${config.xdg.configHome}/forge-session-secrets.sh" ] || . "${config.xdg.configHome}/forge-session-secrets.sh"
      export CLAUDE_SECRET_BACKEND="''${CLAUDE_SECRET_BACKEND:-${secretBackend}}"
      export CLOUDSDK_CONFIG="${config.xdg.configHome}/gcloud"
      export WORKSPACE_MCP_CREDENTIALS_DIR="${config.xdg.cacheHome}/workspace-mcp"
      export GOOGLE_WORKSPACE_CLI_CONFIG_DIR="${config.xdg.configHome}/gws"
      export GOOGLE_WORKSPACE_PROJECT_ID="workspace-mcp-500605"
      export MAGHZ_REMOTE_HOST="31.97.131.41"
      export MAGHZ_REMOTE_USER="maghz-agent"
      export MAGHZ_REMOTE_WORKROOT="/home/maghz-agent/maghz"
      while IFS= read -r k; do
        val="''${!k:-}"
        if [ -n "$val" ]; then
          /bin/launchctl setenv "$k" "$val"
        else
          # Narrowing is real in the launchd domain: a name no backend serves
          # is cleared, so the cutover flip retires stale GUI values at replay
          # instead of leaving them pinned until logout.
          /bin/launchctl unsetenv "$k" || true
        fi
      done < <({ for f in "${sessionCache}" "${opCache}"; do
        [ -f "$f" ] || continue
        grep -oE '^export [A-Za-z_][A-Za-z0-9_]*' "$f" | awk '{print $2}'
      done
      printf '%s\n' ${lib.concatStringsSep " " replayConstants}; } | sort -u)
    '';
  };
  # Per-lane cutover proof: key NAMES only, never values. CLI runs the
  # canonical hook against a temp CLAUDE_ENV_FILE and shows its receipt; TUI
  # probes an interactive login zsh; GUI reads the launchd domain.
  secretsProof = pkgs.writeShellApplication {
    name = "forge-secrets-proof";
    runtimeInputs = [pkgs.bash pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.gawk];
    text = ''
      echo "backend=''${CLAUDE_SECRET_BACKEND:-${secretBackend}}"
      keys="$({ for f in "${sessionCache}" "${opCache}"; do
        [ -f "$f" ] || continue
        grep -oE '^export [A-Za-z_][A-Za-z0-9_]*' "$f" | awk '{print $2}'
      done; } | sort -u)"
      [ -n "$keys" ] || { echo "no session material on disk; run a Claude session first" >&2; exit 1; }
      tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
      echo "--- CLI lane (SessionStart hook, fresh env file)"
      CLAUDE_ENV_FILE="$tmp/env.sh" bash "$HOME/.claude/hooks/setup-env.sh" >"$tmp/alerts" 2>"$tmp/receipt" || true
      sed 's/^/  receipt: /' "$tmp/receipt"
      sed 's/^/  ALERT:   /' "$tmp/alerts"
      echo "  emitted: $(grep -oE '^export [A-Za-z_][A-Za-z0-9_]*' "$tmp/env.sh" 2>/dev/null | awk '{print $2}' | tr '\n' ' ')"
      echo "--- TUI lane (interactive login zsh)"
      ZKEYS="$(printf '%s' "$keys" | tr '\n' ' ')" /bin/zsh -il -c \
        'for k in ''${(s: :)ZKEYS}; do if [ -n "''${(P)k}" ]; then print "  present $k"; else print "  ABSENT  $k"; fi; done' 2>/dev/null
      echo "--- GUI lane (launchctl getenv)"
      while IFS= read -r k; do
        if [ -n "$(/bin/launchctl getenv "$k" 2>/dev/null || true)" ]; then
          echo "  present $k"
        else
          echo "  ABSENT  $k"
        fi
      done <<<"$keys"
    '';
  };
in {
  imports = [inputs.shell-plugins.hmModules.default];

  # --- Shell Plugins: Biometric auth for supported CLIs ------------------------
  # NOTE: gh is intentionally excluded - it uses PAT token via GH_TOKEN env var
  # This ensures gh works in non-interactive contexts (Claude Code, CI, scripts)
  programs._1password-shell-plugins = {
    enable = true;
    plugins = []; # Add other CLIs here if needed (e.g., pkgs.aws-cli)
  };

  home = {
    packages = [secretsProof];

    # --- Environment: Biometric unlock for CLI ----------------------------------
    sessionVariables = {
      OP_BIOMETRIC_UNLOCK_ENABLED = "true";
      CLAUDE_SECRET_BACKEND = secretBackend;
    };

    activation = {
      # --- Setup: op config directory -----------------------------------------------
      # Run BEFORE writeBoundary (validation phase) - safe for idempotent directory creation
      ensure1PasswordDirs = lib.hm.dag.entryBefore ["writeBoundary"] ''
        mkdir -p "${config.xdg.configHome}/op"
        chmod 700 "${config.xdg.configHome}/op"
      '';

      # --- Activation Hook: Generate token cache during rebuild ----------------------
      # CRITICAL: Must run AFTER linkGeneration to ensure template file exists
      # linkGeneration writes xdg.configFile entries after writeBoundary
      injectSecretsFromVault = lib.hm.dag.entryAfter ["linkGeneration" "ensureForgeJupyterToken"] ''
        cache_file="$HOME/.config/hm-op-session.sh"
        template_file="$HOME/.config/op/env.template"
        jupyter_token_file="$HOME/.config/jupyter/forge-token.env"
        tmp_file="$cache_file.tmp.$$"

        # Fail loudly if template missing (indicates DAG ordering bug)
        if [[ ! -f "$template_file" ]]; then
          echo "ERROR: Template file not found: $template_file" >&2
          echo "This indicates a home-manager activation ordering issue." >&2
          exit 1
        fi

        # Create cache file with resolved tokens from 1Password
        echo "Injecting secrets from 1Password vault..." >&2
        mkdir -p "$(dirname "$cache_file")"
        if ${pkgs._1password-cli}/bin/op inject -f -i "$template_file" -o "$tmp_file" >/dev/null; then
          if [[ -f "$jupyter_token_file" ]]; then
            grep -E '^export JUPYTER_TOKEN=' "$jupyter_token_file" >>"$tmp_file"
          fi
          chmod 600 "$tmp_file"
          mv -f "$tmp_file" "$cache_file"
          echo "✓ Tokens cached" >&2
        else
          echo "⚠ Warning: op inject failed - 1Password may not be authenticated. Run: op signin" >&2
          rm -f "$tmp_file"
          if [[ ! -f "$cache_file" ]]; then
            touch "$cache_file"
            chmod 600 "$cache_file"
          fi
        fi

        # Transitional GUI replay: restart the RunAtLoad agent so GUI apps pick up
        # the just-written cache on this switch instead of at next login.
        /bin/launchctl kickstart -k "gui/$UID/org.nix-community.home.gui-op-secrets" >/dev/null 2>&1 || true
      '';

      # Register the GUI Op Secrets app bundle with Launch Services so macOS Login Items & Extensions
      # resolves the agent's AssociatedBundleIdentifiers to "GUI Op Secrets" instead of the "/bin/sh"
      # program name, on every switch rather than only at next login. lsregister -f is idempotent.
      registerGuiOpSecretsApp = lib.hm.dag.entryAfter ["linkGeneration"] ''
        app="$HOME/Applications/GUI Op Secrets.app"
        lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
        if [[ -d "$app" && -x "$lsregister" ]]; then
          "$lsregister" -f "$app" || true
        fi
      '';
    };
  };

  xdg.configFile = {
    # --- op SSH agent seam: one unified key, deterministic offer order ---------
    # The agent serves exactly the unified estate key; op-ssh-sign (git-tools
    # signing rail) resolves the same item by public key. Approval posture is
    # app-level: approve-for-all-applications during active windows.
    "1Password/ssh/agent.toml".text = ''
      [[ssh-keys]]
      item = "Forge SSH Key"
      vault = "Personal"
    '';

    # --- Session-secrets dispatcher: one sourceable file for TUI and GUI lanes -
    # The SessionStart hook maintains the doppler-first session cache; transition
    # falls back to the 1Password cache until the cache exists. The backend flip
    # is the secretBackend row above.
    "forge-session-secrets.sh".text = ''
      case "''${CLAUDE_SECRET_BACKEND:-${secretBackend}}" in
        doppler)
          [ ! -f "${sessionCache}" ] || . "${sessionCache}"
          ;;
        *)
          if [ -f "${sessionCache}" ]; then
            . "${sessionCache}"
          elif [ -f "${opCache}" ]; then
            . "${opCache}"
          fi
          ;;
      esac
    '';

    # --- Secret Template: API keys for op inject --------------------------------
    "op/env.template".text = ''
      # API Keys - resolved during rebuild via "op inject"
      # IMPORTANT: export keyword ensures child processes inherit these variables
      # Update this list when adding new tokens to your 1Password vault

      # CLI tools and APIs
      # NOTE: ANTHROPIC_API_KEY intentionally excluded - use Claude Code OAuth instead
      # Projects needing API key auth should configure it locally
      export GREPTILE_API_KEY="op://Tokens/GREPTILE_API_KEY/token"
      export CODERABBIT_API_KEY="op://Tokens/CODERABBIT_API_KEY/token"
      export OP_SERVICE_ACCOUNT_TOKEN="op://Tokens/OP_SERVICE_ACCOUNT_TOKEN/token"
      export GOOGLE_OAUTH_CLIENT_ID="op://Tokens/GOOGLE_OAUTH_CLIENT_ID/credential"
      export GOOGLE_OAUTH_CLIENT_SECRET="op://Tokens/GOOGLE_OAUTH_CLIENT_SECRET/credential"
      export GOOGLE_WORKSPACE_CLI_CLIENT_ID="op://Tokens/GOOGLE_OAUTH_CLIENT_ID/credential"
      export GOOGLE_WORKSPACE_CLI_CLIENT_SECRET="op://Tokens/GOOGLE_OAUTH_CLIENT_SECRET/credential"
      export RHINO_TOKEN="op://Tokens/RHINO_TOKEN/token"
      export EXA_API_KEY="op://Tokens/Exa API Key/token"
      export PERPLEXITY_API_KEY="op://Tokens/Perplexity Sonar API Key/token"
      export TAVILY_API_KEY="op://Tokens/Tavily Auth Token/token"
      export SONAR_TOKEN="op://Tokens/SONAR_TOKEN/token"
      export CACHIX_AUTH_TOKEN="op://Tokens/Cachix Auth Token - Parametric Forge/token"
      export HOSTINGER_TOKEN="op://Tokens/HOSTINGER_TOKEN/token"
      # HOSTINGER_API_TOKEN is the exact env name the hostinger MCP reads; aliased to the same vault item so
      # Codex (which cannot remap env names at the MCP boundary) and the GUI domain get it ambient correctly.
      export HOSTINGER_API_TOKEN="op://Tokens/HOSTINGER_TOKEN/token"
      export CONTEXT7_API_KEY="op://Tokens/CONTEXT7_API_KEY/token"

      # GitHub CLI (gh prefers GH_TOKEN, GITHUB_TOKEN is fallback for other tools)
      export GH_TOKEN="op://Tokens/Github Token/token"
      export GITHUB_TOKEN="op://Tokens/Github Token/token"

      # GitHub Projects (Classic PAT required - fine-grained PATs don't support Projects API)
      export GH_PROJECTS_TOKEN="op://Tokens/GH_PROJECTS_TOKEN/token"

      # Universal local-pg endpoint - single-sourced from the Tokens vault (Maghz + any pg/mcp skill)
      export MAGHZ_MCP__DATABASE_URI="op://Tokens/MAGHZ_MCP__DATABASE_URI/credential"
    '';
  };

  # --- GUI session secrets: replay session material into the launchd domain ---
  # GUI apps (Codex.app, Claude Desktop) are launched by launchd and never source
  # .zshrc, so they miss the tokens interactive shells receive. This RunAtLoad
  # agent replays the backend-dispatched mode-600 session material via
  # "launchctl setenv"; no secret value enters the Nix store.
  #
  # AssociatedBundleIdentifiers causes macOS Login Items & Extensions to show the
  # bundle's CFBundleDisplayName ("GUI Op Secrets") instead of the basename of
  # ProgramArguments[0], which home-manager's mutateConfig unconditionally sets to
  # "/bin/sh" (producing the generic "sh" entry). The key passes through mutateConfig
  # unchanged; the freeformType in the launchd schema accepts it.
  home.file."Applications/GUI Op Secrets.app/Contents/Info.plist".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key>
      <string>com.parametric-forge.gui-op-secrets</string>
      <key>CFBundleName</key>
      <string>GUI Op Secrets</string>
      <key>CFBundleDisplayName</key>
      <string>GUI Op Secrets</string>
      <key>CFBundleVersion</key>
      <string>1</string>
      <key>CFBundleShortVersionString</key>
      <string>1.0</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>LSUIElement</key>
      <true/>
      <key>LSBackgroundOnly</key>
      <true/>
    </dict>
    </plist>
  '';

  launchd.agents.gui-op-secrets = {
    enable = true;
    config = {
      ProgramArguments = ["${guiOpSecrets}/bin/gui-op-secrets"];
      RunAtLoad = true;
      StandardErrorPath = "${config.xdg.cacheHome}/gui-op-secrets.err.log";
      AssociatedBundleIdentifiers = ["com.parametric-forge.gui-op-secrets"];
    };
  };
}
