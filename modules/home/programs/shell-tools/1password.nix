# Title         : 1password.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/1password.nix
# ----------------------------------------------------------------------------
# 1Password custody: the CLI, SSH agent seam, op-inject token cache on rebuild, and GUI secret replay
{
  config,
  guiSetenv,
  launchdAgent,
  lib,
  pkgs,
  ...
}: let
  opCache = "${config.xdg.stateHome}/op/session.sh";
  # op-injected token rows: NAME -> null (the default item+field, Tokens/NAME/token) | "ITEM/field" override. ANTHROPIC_API_KEY stays excluded —
  # Claude Code OAuth owns that auth. gh prefers GH_TOKEN; GITHUB_TOKEN is the fallback other tools read; gws reads its OAuth client pair.
  tokenRows = {
    GOOGLE_WORKSPACE_CLI_CLIENT_ID = "GOOGLE_OAUTH_CLIENT_ID/credential";
    GOOGLE_WORKSPACE_CLI_CLIENT_SECRET = "GOOGLE_OAUTH_CLIENT_SECRET/credential";
    CACHIX_AUTH_TOKEN = null;
    GH_TOKEN = "GITHUB_TOKEN/token";
    GITHUB_TOKEN = null;
  };
  tokenNames = lib.attrNames tokenRows;
  # GUI-session replay hands the op cache rows to the shared GUI-domain writer (shell.nix); a name the cache leaves empty clears its stale GUI
  # value, and a changed token restarts the resident agents that spawned before it. launchd hands this agent the domain values of its last
  # replay, and the cache rows keep a set value, so each name is unset before the source and a rotated token lands.
  guiOpSecrets = pkgs.writeShellApplication {
    name = "gui-op-secrets";
    text = ''
      unset ${lib.escapeShellArgs tokenNames}
      # shellcheck source=/dev/null
      [ ! -f "${opCache}" ] || . "${opCache}"
      rows=()
      for k in ${lib.escapeShellArgs tokenNames}; do
        rows+=("$k" "''${!k:-}")
      done
      exec ${guiSetenv}/bin/gui-setenv "''${rows[@]}"
    '';
  };
in {
  # The mode-600 session cache every consumer sources (.zshenv, the deploy rail, the GUI replay): one declared path, read as an option.
  options.forge.secrets.sessionCache = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = opCache;
    description = "Path of the op-injected session cache published at activation.";
  };

  config = {
    home = {
      # The CLI on PATH for the operator and the secrets skill; no 1Password shell plugin is enabled (gh keeps GH_TOKEN for non-interactive use).
      packages = [pkgs._1password-cli-current];

      activation = {
        # --- [TOKEN_CACHE]
        # Runs AFTER linkGeneration, so the template it reads (an xdg.configFile entry) is the generation's, and AFTER setupLaunchAgents, so the
        # kickstart below always reaches a bootstrapped replay agent. The op config and state directories are 700 rows of xdg.nix, seeded before
        # linkGeneration.
        injectSecretsFromVault = lib.hm.dag.entryAfter ["linkGeneration" "setupLaunchAgents"] ''
          cache_file="${opCache}"
          template_file="${config.xdg.configHome}/op/env.template"

          # Content gate: op inject needs a 1Password biometric unlock, and HM activation runs under a fresh session each switch, so the CLI's
          # tty-scoped authorization never caches — every switch would fire Touch ID. The template is a store symlink whose realpath changes only
          # when tokenRows does, and the cache carries that realpath as its own first-line comment (a no-op when the cache is sourced), so an
          # ordinary switch that left the secret set alone reads its own provenance and never unlocks 1Password.
          marker="# op-template: $(readlink -f "$template_file")"
          if [[ -s "$cache_file" && "$(head -n1 "$cache_file")" == "$marker" ]]; then
            verboseEcho "Secret template unchanged; skipping op inject"
          else
            # Resolve tokens from 1Password into a mode-600 cache; temp lives in the target directory so the publish rename stays same-filesystem.
            # The marker leads the file, then the exports (a brace group's status is op inject's, so a failed unlock still short-circuits).
            verboseEcho "Injecting secrets from 1Password vault"
            tmp_file="$(mktemp "$cache_file.XXXXXX")"
            if {
              printf '%s\n' "$marker"
              ${pkgs._1password-cli-current}/bin/op inject -f -i "$template_file"
            } >"$tmp_file"; then
              chmod 600 "$tmp_file"
              mv -f "$tmp_file" "$cache_file"
              verboseEcho "Tokens cached"
            else
              echo "WARNING: op inject failed - 1Password may not be authenticated. Run: op signin" >&2
              rm -f "$tmp_file"
            fi
          fi

          # GUI replay: restart the RunAtLoad agent so GUI apps and resident agents pick up a changed cache on this switch instead of at next login.
          /bin/launchctl kickstart -k "gui/$UID/dev.bsamiee.gui-op-secrets"
        '';
      };
    };

    xdg.configFile = {
      # --- [SSH_AGENT_SEAM]
      # The agent serves exactly the one key in Personal, referenced by its item ID so a title change never breaks the seam; op-ssh-sign
      # (git-tools signing rail) resolves the same item by public key. Approval posture is app-level: approve-for-all-applications during
      # active windows.
      "1Password/ssh/agent.toml".text = ''
        [[ssh-keys]]
        item = "3mtwmcjq3ywwglpkrdqt25enhe"
        vault = "Personal"
      '';

      # --- [SECRET_TEMPLATE]
      # Resolved during rebuild via "op inject"; every row folds from tokenRows so a new secret is one name, never a re-spelled op:// path. Each
      # row keeps a value its shell already holds, the never-clobber form of the .zshenv floor.
      "op/env.template".text = lib.concatLines (lib.mapAttrsToList (name: ref: ''export ${name}="''${${name}:-{{ op://Tokens/${
          if ref == null
          then "${name}/token"
          else ref
        } }}}"'') tokenRows);
    };

    # --- [GUI_SESSION_SECRETS]
    # launchd-launched GUI apps never source .zshrc; this RunAtLoad agent replays the mode-600 session material, and no secret value enters the
    # Nix store. RunAtLoad + writer-side kickstart is the event source; WatchPaths on the cache file is race-prone (launchd.plist(5)), and the
    # cache writer already owns the deterministic replay trigger.
    launchd.agents.gui-op-secrets = launchdAgent {
      name = "gui-op-secrets";
      argv = ["${guiOpSecrets}/bin/gui-op-secrets"];
      RunAtLoad = true;
    };
  };
}
