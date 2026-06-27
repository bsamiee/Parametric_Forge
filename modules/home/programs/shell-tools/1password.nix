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
  # GUI-session secret replay: source the resolved op cache and re-export each key
  # into the launchd GUI domain via "launchctl setenv" so GUI-launched apps
  # (Codex.app, Claude Desktop) inherit the same tokens as interactive shells.
  guiOpSecrets = pkgs.writeShellApplication {
    name = "gui-op-secrets";
    runtimeInputs = [pkgs.gnugrep pkgs.gawk];
    text = ''
      cache="$HOME/.config/hm-op-session.sh"
      [ -f "$cache" ] || exit 0
      # shellcheck source=/dev/null
      . "$cache"
      while IFS= read -r k; do
        val="''${!k:-}"
        if [ -n "$val" ]; then
          /bin/launchctl setenv "$k" "$val"
        fi
      done < <(grep -oE '^export [A-Za-z_][A-Za-z0-9_]*' "$cache" | awk '{print $2}')
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
    # --- Environment: Biometric unlock for CLI ----------------------------------
    sessionVariables = {
      OP_BIOMETRIC_UNLOCK_ENABLED = "true";
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
      injectSecretsFromVault = lib.hm.dag.entryAfter ["linkGeneration"] ''
        cache_file="$HOME/.config/hm-op-session.sh"
        template_file="$HOME/.config/op/env.template"
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

  # --- Secret Template: API keys for op inject -----------------------------------
  xdg.configFile."op/env.template".text = ''
    # API Keys - resolved during rebuild via "op inject"
    # IMPORTANT: export keyword ensures child processes inherit these variables
    # Update this list when adding new tokens to your 1Password vault

    # CLI tools and APIs
    # NOTE: ANTHROPIC_API_KEY intentionally excluded - use Claude Code OAuth instead
    # Projects needing API key auth should configure it locally
    export GREPTILE_API_KEY="op://Tokens/GREPTILE_API_KEY/token"
    export CODERABBIT_TOKEN="op://Tokens/CODERABBIT_TOKEN/token"
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

  # --- GUI session secrets: replay the op cache into the launchd domain at login ---
  # GUI apps (Codex.app, Claude Desktop) are launched by launchd and never source
  # .zshrc, so they miss the op-injected tokens that interactive shells receive. This
  # RunAtLoad agent replays the already-resolved 600 cache via "launchctl setenv",
  # keeping op the single source with no secret value in the Nix store.
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
