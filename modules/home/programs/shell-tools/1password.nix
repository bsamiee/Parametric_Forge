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
  loginPassword = "op://Personal/MacBook login/password";
  tokenRows = {
    GREPTILE_API_KEY = null;
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
    PLAYWRIGHT_MCP_EXTENSION_TOKEN = null;
    CODERABBIT_API_KEY = null;
    CLIMICROSOFT365_ENTRAAPPID = null;
    CLIMICROSOFT365_TENANT = null;
    MICROSOFT_AGENT_CERTIFICATE = null;
  };
  fileRows = lib.mapAttrs' (file: lib.nameValuePair "${config.xdg.configHome}/gam/${file}") {
    "oauth2.txt" = "GOOGLE_WORKSPACE_GAM_OAUTH2";
    "client_secrets.json" = "GOOGLE_WORKSPACE_GAM_CLIENT_SECRETS";
    "oauth2service.json" = "GOOGLE_WORKSPACE_SERVICE_ACCOUNT";
  };
  tokenNames = lib.attrNames tokenRows;
  stampName = "FORGE_OP_STAMP";
  namesName = "FORGE_OP_NAMES";
  cacheNames = tokenNames ++ [stampName namesName];
  guiOpSecrets = pkgs.writeShellApplication {
    name = "gui-op-secrets";
    text = ''
      unset ${lib.escapeShellArgs cacheNames}
      # shellcheck source=/dev/null
      [ ! -f "${opCache}" ] || . "${opCache}"
      rows=()
      for k in ${lib.escapeShellArgs cacheNames}; do
        rows+=("$k" "''${!k:-}")
      done
      exec ${guiSetenv}/bin/gui-setenv gui-op-secrets "''${rows[@]}"
    '';
  };
in {
  options.forge.secrets.sessionCache = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = opCache;
    description = "Path of the op-injected session cache published at activation.";
  };

  config = {
    home = {
      packages = [pkgs._1password-cli-current pkgs.doppler];
      file.".doppler".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/doppler";

      activation = {
        # --- [TOKEN_CACHE]
        injectSecretsFromVault = lib.hm.dag.entryAfter ["linkGeneration" "setupLaunchAgents"] ''
          cache_file="${opCache}"
          account_file="${opServiceAccount.file}"
          template_file="${config.xdg.configHome}/op/env.template"

          if [[ -v DRY_RUN ]]; then
            echo "op inject -i $template_file > $cache_file"
          else
            verboseEcho "Injecting secrets from 1Password vault"
            tmp_file="$(mktemp "$cache_file.XXXXXX")"
            if { [[ -s "$account_file" ]] || ${op} read --force --out-file "$account_file" ${lib.escapeShellArg opServiceAccount.reference} >/dev/null; } \
              && OP_SERVICE_ACCOUNT_TOKEN="$(<"$account_file")" ${op} inject -i "$template_file" >"$tmp_file"; then
              stamp="$(/usr/bin/shasum -a 256 <"$tmp_file")"
              /usr/bin/sed -i "" "s/@stamp@/''${stamp:0:16}/g" "$tmp_file"
              chmod 600 "$tmp_file"
              mv -f "$tmp_file" "$cache_file"
              verboseEcho "Tokens cached"
            else
              echo "WARNING: op inject failed; $cache_file keeps its previous tokens. After rotating the service-account token, remove $account_file, then switch again." >&2
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

        # --- [AUTO_LOGIN_PASSWORD]
        restoreAutoLoginPassword = lib.hm.dag.entryAfter ["injectSecretsFromVault"] ''
          if [[ ! -e /etc/kcpassword ]]; then
            if [[ -v DRY_RUN ]]; then
              echo "op read ${loginPassword} | kcpassword > /etc/kcpassword"
            elif login_password="$(${op} read ${lib.escapeShellArg loginPassword})" && {
              mapfile -t login_bytes < <(printf '%s' "$login_password" | /usr/bin/od -An -v -tu1 | /usr/bin/tr -s ' ' '\n' | /usr/bin/sed '/^$/d')
              login_bytes+=(0)
              while ((''${#login_bytes[@]} % 12)); do login_bytes+=(0); done
              kcpassword_key=(0x7D 0x89 0x52 0x23 0xD2 0xBC 0xDD 0xEA 0xA3 0xB9 0x1F)
              for i in "''${!login_bytes[@]}"; do
                printf "\\x$(printf '%02x' $((login_bytes[i] ^ kcpassword_key[i % 11])))"
              done | /usr/bin/sudo -n /bin/sh -c 'umask 077 && /bin/cat >/etc/kcpassword.next && /bin/mv -f /etc/kcpassword.next /etc/kcpassword'
            }; then
              verboseEcho "Restored /etc/kcpassword for automatic login"
            else
              echo "WARNING: /etc/kcpassword is absent and was not restored, so automatic login is off. Unlock the 1Password app, then switch again." >&2
            fi
            unset login_password login_bytes
          fi
        '';
      };
    };

    xdg.configFile = {
      # --- [SSH_AGENT_SEAM]
      "1Password/ssh/agent.toml".text = ''
        [[ssh-keys]]
        item = "3mtwmcjq3ywwglpkrdqt25enhe"
        vault = "Personal"
      '';

      # --- [SECRET_TEMPLATE]
      "op/env.template".text =
        ''
          [ "''${${stampName}:-}" = "@stamp@" ] || eval "unset ''${${namesName}:-} ${toString tokenNames}"
          export ${stampName}="@stamp@"
          export ${namesName}="${toString tokenNames}"
        ''
        + lib.concatLines (lib.mapAttrsToList (name: ref: ''export ${name}="''${${name}:-{{ op://Tokens/${
            if ref == null
            then "${name}/token"
            else ref
          } }}}"'') tokenRows);
    };

    # --- [GUI_SESSION_SECRETS]
    launchd.agents.gui-op-secrets = launchdAgent {
      name = "gui-op-secrets";
      argv = ["${guiOpSecrets}/bin/gui-op-secrets"];
      RunAtLoad = true;
    };
  };
}
