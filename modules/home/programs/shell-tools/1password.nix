# Title         : 1password.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/1password.nix
# ----------------------------------------------------------------------------
# 1Password custody: biometric CLI unlock, SSH agent seam, op-inject token cache on rebuild, and GUI secret replay
{
  config,
  forgeAgent,
  lib,
  pkgs,
  inputs,
  ...
}: let
  opCache = "${config.xdg.configHome}/hm-op-session.sh";
  # op-injected token rows: NAME -> null (the default item+field, Tokens/NAME/token) | "ITEM/field" override. ANTHROPIC_API_KEY stays excluded —
  # Claude Code OAuth owns that auth. gh prefers GH_TOKEN; GITHUB_TOKEN is the fallback other tools read. GH_PROJECTS_TOKEN is a classic PAT
  # (fine-grained PATs do not reach the Projects API).
  tokenRows = {
    GREPTILE_API_KEY = null;
    CODERABBIT_API_KEY = null;
    OP_SERVICE_ACCOUNT_TOKEN = null;
    GOOGLE_OAUTH_CLIENT_ID = "GOOGLE_OAUTH_CLIENT_ID/credential";
    GOOGLE_OAUTH_CLIENT_SECRET = "GOOGLE_OAUTH_CLIENT_SECRET/credential";
    GOOGLE_WORKSPACE_CLI_CLIENT_ID = "GOOGLE_OAUTH_CLIENT_ID/credential";
    GOOGLE_WORKSPACE_CLI_CLIENT_SECRET = "GOOGLE_OAUTH_CLIENT_SECRET/credential";
    RHINO_TOKEN = null;
    EXA_API_KEY = null;
    PERPLEXITY_API_KEY = null;
    TAVILY_API_KEY = null;
    CACHIX_AUTH_TOKEN = null;
    HOSTINGER_API_TOKEN = null;
    CONTEXT7_API_KEY = null;
    ILLUSTRATOR_MCP_TOKEN = null;
    GH_TOKEN = "GITHUB_TOKEN/token";
    GITHUB_TOKEN = null;
    GH_PROJECTS_TOKEN = null;
  };
  # Replay constants as rows: one declaration owns name AND value; the export block and the replay-manifest name set both derive from it.
  replayRows = {
    CLOUDSDK_CONFIG = "${config.xdg.configHome}/gcloud";
    GOOGLE_WORKSPACE_CLI_CONFIG_DIR = "${config.xdg.configHome}/gws";
    GOOGLE_WORKSPACE_PROJECT_ID = "workspace-mcp-500605";
  };
  # GUI-session replay writes the op cache into the launchd domain; a missing name clears its stale GUI value.
  guiOpSecrets = pkgs.writeShellApplication {
    name = "gui-op-secrets";
    runtimeInputs = [pkgs.coreutils];
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
      done < <(printf '%s\n' ${lib.concatMapStringsSep " " (c: "\"${c}\"") (lib.attrNames (tokenRows // replayRows))} | sort -u)
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

        # Content gate: op inject needs a 1Password biometric unlock, and HM activation runs under a fresh session each switch, so the CLI's
        # tty-scoped authorization never caches — every switch would fire Touch ID. The template is a store symlink whose realpath changes only
        # when tokenRows does, and the cache carries that realpath as its own first-line comment (a no-op when the cache is sourced), so an
        # ordinary switch that left the secret set alone reads its own provenance and never unlocks 1Password.
        marker="# forge-op-template: $(readlink -f "$template_file")"
        if [[ -s "$cache_file" && "$(head -n1 "$cache_file")" == "$marker" ]]; then
          echo "Secret template unchanged; skipping op inject" >&2
        else
          # Resolve tokens from 1Password into a mode-600 cache; temp lives in the target directory so the publish rename stays same-filesystem.
          # The marker leads the file, then the exports (a brace group's status is op inject's, so a failed unlock still short-circuits).
          echo "Injecting secrets from 1Password vault..." >&2
          mkdir -p "$(dirname "$cache_file")"
          tmp_file="$(mktemp "$cache_file.XXXXXX")"
          if {
            printf '%s\n' "$marker"
            ${pkgs._1password-cli}/bin/op inject -f -i "$template_file"
          } >"$tmp_file"; then
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
        fi

        # GUI replay: restart the RunAtLoad agent so GUI apps pick up the current cache on this switch instead of at next login.
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
    # Resolved during rebuild via "op inject"; every row folds from tokenRows so a new secret is one name, never a re-spelled op:// path.
    "op/env.template".text = lib.concatLines (lib.mapAttrsToList (name: ref: ''export ${name}="op://Tokens/${
        if ref == null
        then "${name}/token"
        else ref
      }"'') tokenRows);
  };

  # --- [GUI_SESSION_SECRETS]
  # launchd-launched GUI apps never source .zshrc; this RunAtLoad agent replays the mode-600 session material, and no secret value enters the
  # Nix store. The bundle-apps row makes Login Items & Extensions show the display name the agent's AssociatedBundleIdentifiers resolves to.
  forge.bundleApps.gui-op-secrets = "GUI Op Secrets";

  # RunAtLoad + writer-side kickstart is the event source; WatchPaths on the cache file is race-prone (launchd.plist(5)), and the cache writer
  # already owns the deterministic replay trigger.
  launchd.agents.gui-op-secrets = forgeAgent {
    name = "gui-op-secrets";
    argv = ["${guiOpSecrets}/bin/gui-op-secrets"];
    RunAtLoad = true;
  };
}
