# Title         : 1password.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/1password.nix
# ----------------------------------------------------------------------------
# 1Password custody: biometric CLI unlock, SSH agent seam, op-inject token cache on rebuild, and GUI secret replay
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  opCache = "${config.xdg.configHome}/hm-op-session.sh";
  # Replay constants as rows: one declaration owns name AND value; the export block and the replay-manifest name set both derive from it.
  replayRows = {
    CLOUDSDK_CONFIG = "${config.xdg.configHome}/gcloud";
    WORKSPACE_MCP_CREDENTIALS_DIR = "${config.xdg.cacheHome}/workspace-mcp";
    GOOGLE_WORKSPACE_CLI_CONFIG_DIR = "${config.xdg.configHome}/gws";
    GOOGLE_WORKSPACE_PROJECT_ID = "workspace-mcp-500605";
  };
  # GUI-session replay writes the op cache into the launchd domain; a missing name clears its stale GUI value.
  guiOpSecrets = pkgs.writeShellApplication {
    name = "gui-op-secrets";
    runtimeInputs = [pkgs.coreutils pkgs.gnugrep pkgs.gawk];
    text = ''
      # shellcheck source=/dev/null
      [ ! -f "${opCache}" ] || . "${opCache}"
      ${lib.concatStringsSep "\n      " (lib.mapAttrsToList (k: v: ''export ${k}="${v}"'') replayRows)}
      # Replay manifest (key NAMES only, mode 600): the set names forge-accept asserts against the live gui domain for lane parity. The temp
      # lives beside its rename target so the publish stays same-filesystem atomic.
      mkdir -p "${config.xdg.cacheHome}/forge-secrets"
      names_tmp="$(mktemp "${config.xdg.cacheHome}/forge-secrets/gui-replay.names.XXXXXX")"
      trap 'rm -f "$names_tmp"' EXIT
      while IFS= read -r k; do
        val="''${!k:-}"
        if [ -n "$val" ]; then
          /bin/launchctl setenv "$k" "$val"
          printf '%s\n' "$k" >>"$names_tmp"
        else
          # Narrowing is real in the launchd domain: a name no backend serves is cleared, so the cutover flip retires
          # stale GUI values at replay instead of leaving them pinned until logout.
          /bin/launchctl unsetenv "$k" || true
        fi
      done < <({
      [ ! -f "${opCache}" ] || awk 'match($0, /^export [A-Za-z_][A-Za-z0-9_]*/) {print substr($0, 8, RLENGTH - 7)}' "${opCache}"
      printf '%s\n' ${lib.concatMapStringsSep " " (c: "\"${c}\"") (lib.attrNames replayRows)}; } | sort -u)
      chmod 600 "$names_tmp"
      mv -f "$names_tmp" "${config.xdg.cacheHome}/forge-secrets/gui-replay.names"
      trap - EXIT
    '';
  };
in {
  imports = [inputs.shell-plugins.hmModules.default];

  # --- [SHELL_PLUGINS]
  # gh stays excluded: GH_TOKEN keeps it working in non-interactive contexts.
  programs._1password-shell-plugins = {
    enable = true;
    plugins = [];
  };

  home = {
    # --- [BIOMETRIC_UNLOCK]
    sessionVariables = {
      OP_BIOMETRIC_UNLOCK_ENABLED = "true";
    };

    activation = {
      # --- [OP_CONFIG_DIR]
      # entryBefore writeBoundary lands this in the validation phase, before config-file link generation.
      ensure1PasswordDirs = lib.hm.dag.entryBefore ["writeBoundary"] ''
        mkdir -p "${config.xdg.configHome}/op"
        chmod 700 "${config.xdg.configHome}/op"
      '';

      # --- [TOKEN_CACHE]
      # Runs AFTER linkGeneration: xdg.configFile entries (the template) land after writeBoundary, so an earlier run would read a stale template.
      injectSecretsFromVault = lib.hm.dag.entryAfter ["linkGeneration"] ''
        cache_file="$HOME/.config/hm-op-session.sh"
        template_file="$HOME/.config/op/env.template"

        # A missing template is a DAG-ordering defect; fail loudly.
        if [[ ! -f "$template_file" ]]; then
          echo "ERROR: template not found: $template_file (activation ordering defect)" >&2
          exit 1
        fi

        # Resolve tokens from 1Password into a mode-600 cache; temp lives in the target directory so the publish rename stays same-filesystem.
        echo "Injecting secrets from 1Password vault..." >&2
        mkdir -p "$(dirname "$cache_file")"
        tmp_file="$(mktemp "$cache_file.XXXXXX")"
        if ${pkgs._1password-cli}/bin/op inject -f -i "$template_file" -o "$tmp_file" >/dev/null; then
          chmod 600 "$tmp_file"
          mv -f "$tmp_file" "$cache_file"
          echo "Tokens cached" >&2
        else
          echo "WARNING: op inject failed - 1Password may not be authenticated. Run: op signin" >&2
          rm -f "$tmp_file"
          if [[ ! -f "$cache_file" ]]; then
            touch "$cache_file"
            chmod 600 "$cache_file"
          fi
        fi

        # GUI replay: restart the RunAtLoad agent so GUI apps pick up the just-written cache on this switch instead of at next login.
        /bin/launchctl kickstart -k "gui/$UID/com.parametric-forge.gui-op-secrets" >/dev/null 2>&1 || true
      '';
    };
  };

  xdg.configFile = {
    # --- [SSH_AGENT_SEAM]
    # The agent serves exactly the unified estate key; op-ssh-sign (git-tools signing rail) resolves the same item by public key. Approval
    # posture is app-level: approve-for-all-applications during active windows.
    "1Password/ssh/agent.toml".text = ''
      [[ssh-keys]]
      item = "Forge SSH Key"
      vault = "Personal"
    '';

    # --- [SESSION_SECRETS]
    # Interactive shells source the op-injected cache through one stable path.
    "forge-session-secrets.sh".text = ''
      [ ! -f "${opCache}" ] || . "${opCache}"
    '';

    # --- [SECRET_TEMPLATE]
    "op/env.template".text = ''
      # API keys resolved during rebuild via "op inject"; ANTHROPIC_API_KEY stays excluded — Claude Code OAuth owns that auth.
      export GREPTILE_API_KEY="op://Tokens/GREPTILE_API_KEY/token"
      export CODERABBIT_API_KEY="op://Tokens/CODERABBIT_API_KEY/token"
      export OP_SERVICE_ACCOUNT_TOKEN="op://Tokens/OP_SERVICE_ACCOUNT_TOKEN/token"
      export GOOGLE_OAUTH_CLIENT_ID="op://Tokens/GOOGLE_OAUTH_CLIENT_ID/credential"
      export GOOGLE_OAUTH_CLIENT_SECRET="op://Tokens/GOOGLE_OAUTH_CLIENT_SECRET/credential"
      export GOOGLE_WORKSPACE_CLI_CLIENT_ID="op://Tokens/GOOGLE_OAUTH_CLIENT_ID/credential"
      export GOOGLE_WORKSPACE_CLI_CLIENT_SECRET="op://Tokens/GOOGLE_OAUTH_CLIENT_SECRET/credential"
      export RHINO_TOKEN="op://Tokens/RHINO_TOKEN/token"
      export EXA_API_KEY="op://Tokens/EXA_API_KEY/token"
      export PERPLEXITY_API_KEY="op://Tokens/PERPLEXITY_API_KEY/token"
      export TAVILY_API_KEY="op://Tokens/TAVILY_API_KEY/token"
      export CACHIX_AUTH_TOKEN="op://Tokens/CACHIX_AUTH_TOKEN/token"
      export HOSTINGER_API_TOKEN="op://Tokens/HOSTINGER_API_TOKEN/token"
      export CONTEXT7_API_KEY="op://Tokens/CONTEXT7_API_KEY/token"

      # GitHub CLI (gh prefers GH_TOKEN, GITHUB_TOKEN is fallback for other tools)
      export GH_TOKEN="op://Tokens/GITHUB_TOKEN/token"
      export GITHUB_TOKEN="op://Tokens/GITHUB_TOKEN/token"

      # GitHub Projects (Classic PAT required - fine-grained PATs don't support Projects API)
      export GH_PROJECTS_TOKEN="op://Tokens/GH_PROJECTS_TOKEN/token"
    '';
  };

  # --- [GUI_SESSION_SECRETS]
  # launchd-launched GUI apps never source .zshrc; this RunAtLoad agent replays the mode-600 session material, and no secret value enters the
  # Nix store. The bundle-apps row makes Login Items & Extensions show the display name the agent's AssociatedBundleIdentifiers resolves to.
  forge.bundleApps.gui-op-secrets = "GUI Op Secrets";

  # RunAtLoad + writer-side kickstart is the event source; WatchPaths on the cache file is race-prone (launchd.plist(5)), and the cache writer
  # already owns the deterministic replay trigger.
  launchd.agents.gui-op-secrets = {
    enable = true;
    config = {
      Label = "com.parametric-forge.gui-op-secrets";
      ProgramArguments = ["${guiOpSecrets}/bin/gui-op-secrets"];
      RunAtLoad = true;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-gui-op-secrets.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-gui-op-secrets.log";
      AssociatedBundleIdentifiers = ["com.parametric-forge.gui-op-secrets"];
    };
  };
}
