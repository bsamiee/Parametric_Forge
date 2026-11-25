{
  config,
  guiSetenv,
  launchdAgent,
  lib,
  pkgs,
  ...
}: let
  opCache = "${config.xdg.stateHome}/op/session.sh";
  opServiceAccount = {
    file = "${config.xdg.stateHome}/op/service-account";
    reference = "op://Tokens/OP_SERVICE_ACCOUNT_TOKEN/token";
  };
  op = lib.getExe pkgs._1password-cli-current;
  tokenRows = {
    GREPTILE_API_KEY = null;
    GEMINI_API_KEY = null;
    GOOGLE_DEVELOPER_KNOWLEDGE_API_KEY = null;
    GOG_KEYRING_PASSWORD = null;
    EXA_API_KEY = null;
    TAVILY_API_KEY = null;
    CACHIX_AUTH_TOKEN = null;
    CONTEXT7_API_KEY = null;
    BLENDERMCP_SKETCHFAB_API_KEY = null;
    BLENDERMCP_POLYPIZZA_API_KEY = null;
    GH_TOKEN = "GH_PROJECTS_TOKEN/token";
    GITHUB_TOKEN = null;
    GH_PROJECTS_TOKEN = null;
    GITHUB_APP_ID = null;
    GITHUB_APP_INSTALLATION_ID = null;
    GITHUB_APP_PRIVATE_KEY = null;
    HOSTINGER_API_TOKEN = null;
    ARENA_TOKEN = null;
    OPENALEX_API_KEY = null;
    R2_ACCESS_KEY_ID = null;
    R2_SECRET_ACCESS_KEY = null;
    R2_ENDPOINT = null;
    RCLONE_CONFIG_R2_ACCESS_KEY_ID = "R2_ACCESS_KEY_ID/token";
    RCLONE_CONFIG_R2_SECRET_ACCESS_KEY = "R2_SECRET_ACCESS_KEY/token";
    RCLONE_CONFIG_R2_ENDPOINT = "R2_ENDPOINT/token";
    TSCLI_OAUTH_CLIENT_ID = "TAILSCALE_OAUTH_CLIENT_ID/token";
    TSCLI_OAUTH_CLIENT_SECRET = "TAILSCALE_OAUTH_CLIENT_SECRET/credential";
    RCLONE_CONFIG_B2_ACCOUNT = "BACKBLAZE_ACCESS_KEY_ID/token";
    RCLONE_CONFIG_B2_KEY = "BACKBLAZE_SECRET_ACCESS_KEY/token";
    CLOUDFLARE_API_TOKEN = null;
    CLOUDFLARE_ACCOUNT_ID = null;
    OPENTOPOGRAPHY_API_KEY = null;
    GODADDY_API_TOKEN = null;
    CODERABBIT_API_KEY = null;
    CLIMICROSOFT365_ENTRAAPPID = null;
    CLIMICROSOFT365_TENANT = null;
    MICROSOFT_AGENT_CERTIFICATE = null;
    NODE_AUTH_TOKEN = null;
    UV_PUBLISH_TOKEN = null;
    CARGO_REGISTRY_TOKEN = null;
  };
  fileRows = lib.mapAttrs' (file: lib.nameValuePair "${config.xdg.configHome}/gam/${file}") {
    "oauth2.txt" = "GOOGLE_WORKSPACE_GAM_OAUTH2";
    "client_secrets.json" = "GOOGLE_WORKSPACE_GAM_CLIENT_SECRETS";
    "oauth2service.json" = "GOOGLE_WORKSPACE_SERVICE_ACCOUNT";
  };
  tokenNames = lib.attrNames tokenRows;
  stampName = "SESSION_CACHE_STAMP";
  namesName = "SESSION_CACHE_NAMES";
  cacheNames = tokenNames ++ [stampName namesName];
  tokenEnv = pkgs.writeText "session-tokens.env" (lib.concatLines (lib.mapAttrsToList (name: ref: "${name}=op://Tokens/${
      if ref == null
      then "${name}/token"
      else ref
    }")
    tokenRows));
  cacheHeader = pkgs.writeText "session-cache-header.sh" ''
    [ "''${${stampName}:-}" = "@stamp@" ] || eval "unset ''${${namesName}:-} ${toString tokenNames}"
    export ${stampName}="@stamp@"
    export ${namesName}="${toString tokenNames}"
  '';
  cacheRows = pkgs.writeShellScript "session-cache-rows" ''
    for name in ${toString tokenNames}; do
      printf '[ -n "''${%s:-}" ] || export %s=%q\n' "$name" "$name" "''${!name}"
    done
  '';
  guiOpSecrets = pkgs.writeShellApplication {
    name = "gui-op-secrets";
    excludeShellChecks = ["SC1091"];
    text = ''
      unset ${lib.escapeShellArgs cacheNames}
      [ ! -f "${opCache}" ] || . "${opCache}"
      rows=()
      for k in ${lib.escapeShellArgs cacheNames}; do
        rows+=("$k" "''${!k:-}")
      done
      exec ${guiSetenv}/bin/gui-setenv gui-op-secrets "''${rows[@]}"
    '';
  };
in {
  config = {
    _module.args.opSessionCache = opCache;
    home = {
      packages = [pkgs._1password-cli-current pkgs.doppler];
      file.".doppler".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/doppler";

      activation = {
        # --- [TOKEN_CACHE]
        injectSecretsFromVault = lib.hm.dag.entryAfter ["linkGeneration" "setupLaunchAgents"] ''
          cache_file="${opCache}"
          account_file="${opServiceAccount.file}"

          if [[ -v DRY_RUN ]]; then
            echo "op run --env-file ${tokenEnv} -- ${cacheRows} > $cache_file"
          else
            verboseEcho "Injecting secrets from 1Password vault"
            tmp_file="$(mktemp "$cache_file.XXXXXX")"
            if { [[ -s "$account_file" ]] || ${op} read --force --out-file "$account_file" ${lib.escapeShellArg opServiceAccount.reference} >/dev/null; } \
              && { /bin/cat ${cacheHeader} && /usr/bin/env -i HOME="$HOME" OP_SERVICE_ACCOUNT_TOKEN="$(<"$account_file")" ${op} run --no-masking --env-file ${tokenEnv} -- ${cacheRows}; } >"$tmp_file"; then
              stamp="$(/usr/bin/shasum -a 256 <"$tmp_file")"
              /usr/bin/sed -i "" "s/@stamp@/''${stamp:0:16}/g" "$tmp_file"
              chmod 600 "$tmp_file"
              mv -f "$tmp_file" "$cache_file"
              verboseEcho "Tokens cached"
            else
              echo "WARNING: op run failed; $cache_file keeps its previous tokens. After rotating the service-account token, remove $account_file, then switch again." >&2
              rm -f "$tmp_file"
            fi
          fi

          replay_label=${lib.escapeShellArg config.launchd.agents.gui-op-secrets.config.Label}
          replay_pid=$(/bin/launchctl list | /usr/bin/awk -v label="$replay_label" '$3 == label && $1 != "-" { print $1 }')
          if [[ -n "$replay_pid" ]]; then
            run ${lib.getExe' pkgs.coreutils "tail"} --pid="$replay_pid" -f /dev/null
          fi
          run /bin/launchctl kickstart "gui/$UID/$replay_label"
        '';

        # --- [SECRET_FILES]
        restoreSecretFiles = lib.hm.dag.entryAfter ["injectSecretsFromVault"] (lib.concatStrings (lib.mapAttrsToList (file: item: ''
            if [[ ! -s ${lib.escapeShellArg file} ]]; then
              if [[ -v DRY_RUN ]]; then
                echo "op read op://Tokens/${item}/token > ${file}"
              elif mkdir -p ${lib.escapeShellArg (dirOf file)} \
                && OP_SERVICE_ACCOUNT_TOKEN="$(<${lib.escapeShellArg opServiceAccount.file})" ${op} read --force --out-file ${lib.escapeShellArg file} ${lib.escapeShellArg "op://Tokens/${item}/token"} >/dev/null; then
                verboseEcho "Restored ${file}"
              else
                echo "WARNING: ${file} is absent and item ${item} did not restore it" >&2
              fi
            fi
          '')
          fileRows));
      };
    };

    xdg.configFile = {
      # --- [SSH_AGENT_SEAM]
      "1Password/ssh/agent.toml".text = ''
        [[ssh-keys]]
        item = "3mtwmcjq3ywwglpkrdqt25enhe"
        vault = "Personal"
      '';

      # --- [REGISTRY_AUTH]
      "pnpm/auth.ini".text = "//registry.npmjs.org/:_authToken=\${NODE_AUTH_TOKEN}\n";
    };

    # --- [GUI_SESSION_SECRETS]
    launchd.agents.gui-op-secrets = launchdAgent {
      name = "gui-op-secrets";
      argv = ["${guiOpSecrets}/bin/gui-op-secrets"];
      RunAtLoad = true;
    };
  };
}
