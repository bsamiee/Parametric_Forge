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
  # GUI-session replay writes the op cache into the launchd domain; a missing name clears its stale GUI value.
  guiOpSecrets = pkgs.writeShellApplication {
    name = "gui-op-secrets";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      # shellcheck source=/dev/null
      [ ! -f "${opCache}" ] || . "${opCache}"
      while IFS= read -r k; do
        val="''${!k:-}"
        if [ -n "$val" ]; then
          /bin/launchctl setenv "$k" "$val"
        else
          # Narrowing is real in the launchd domain: a name no backend serves is cleared, so the cutover flip retires
          # stale GUI values at replay instead of leaving them pinned until logout.
          /bin/launchctl unsetenv "$k"
        fi
      done < <(printf '%s\n' ${lib.concatMapStringsSep " " (c: "\"${c}\"") (lib.attrNames tokenRows)} | sort -u)
    '';
  };
in {
  # The mode-600 session cache every consumer sources (shell init, the deploy rail): one declared path, read as an option.
  options.forge.secrets.sessionCache = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = opCache;
    description = "Path of the op-injected session cache published at activation.";
  };

  config = {
    home = {
      # The CLI on PATH for the operator and the secrets skill; no 1Password shell plugin is enabled (gh keeps GH_TOKEN for non-interactive use).
      packages = [pkgs._1password-cli];

      # --- [BIOMETRIC_UNLOCK]
      sessionVariables = {
        OP_BIOMETRIC_UNLOCK_ENABLED = "true";
      };

      activation = {
        # --- [TOKEN_CACHE]
        # Runs AFTER linkGeneration, so the template it reads (an xdg.configFile entry) is the generation's, and AFTER setupLaunchAgents, so the
        # kickstart below always reaches a bootstrapped replay agent. The op config directory is a 700 row of xdg.nix, seeded before linkGeneration.
        injectSecretsFromVault = lib.hm.dag.entryAfter ["linkGeneration" "setupLaunchAgents"] ''
          cache_file="${opCache}"
          template_file="${config.xdg.configHome}/op/env.template"

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
          /bin/launchctl kickstart -k "gui/$UID/com.parametric-forge.gui-op-secrets"
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
  };
}
