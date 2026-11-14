{
  config,
  guiSetenv,
  host,
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
    NTFY_TOKEN = "NTFY_OWNER_TOKEN/token";
    GATUS_HEARTBEAT_TOKEN = null;
    CLOUDFLARE_API_TOKEN = null;
    CLOUDFLARE_ACCOUNT_ID = null;
    OPENTOPOGRAPHY_API_KEY = null;
    GODADDY_API_TOKEN = null;
    PLAYWRIGHT_MCP_EXTENSION_TOKEN = null;
  };
  fileRows = lib.mapAttrs' (file: lib.nameValuePair "${config.xdg.configHome}/gam/${file}") {
    "oauth2.txt" = "GOOGLE_WORKSPACE_GAM_OAUTH2";
    "client_secrets.json" = "GOOGLE_WORKSPACE_GAM_CLIENT_SECRETS";
    "oauth2service.json" = "GOOGLE_WORKSPACE_SERVICE_ACCOUNT";
  };
  tokenNames = lib.attrNames tokenRows;
  stampName = "FORGE_OP_STAMP";
  cacheNames = tokenNames ++ [stampName];
  opCensus = "${config.xdg.stateHome}/op/secret-census";
  censusReaders =
    map (path: "${config.home.homeDirectory}/${path}") ["Developer/Rasm" ".claude/settings.json" ".claude.json" ".codex/config.toml" ".gemini/config/mcp_config.json" ".gemini/settings.json"]
    ++ [host.flakeRoot];
  secretCensus = pkgs.writeShellApplication {
    name = "secret-census";
    runtimeInputs = [pkgs._1password-cli-current pkgs.coreutils pkgs.doppler pkgs.gawk pkgs.gnused pkgs.jq pkgs.ripgrep];
    text = ''
      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT
      cache=${lib.escapeShellArg "${opCensus}.items.json"}
      hashed() {
        while IFS=$'\t' read -r key encoded; do
          printf '%s\t%s\t%s\n' "$key" \
            "$(base64 -d <<<"$encoded" | sha256sum | cut -c1-16)" \
            "$(base64 -d <<<"$encoded" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' | sha256sum | cut -c1-16)"
        done
      }
      listed() { paste -sd, - | sed 's/,/, /g'; }

      OP_SERVICE_ACCOUNT_TOKEN="$(<${lib.escapeShellArg opServiceAccount.file})"
      export OP_SERVICE_ACCOUNT_TOKEN DOPPLER_CONFIG_DIR=${lib.escapeShellArg "${config.xdg.configHome}/doppler"}
      [[ -s $cache ]] || echo '{}' >"$cache"
      op item list --vault Tokens --format json >"$work/list.json"
      jq -c --slurpfile cache "$cache" '[.[] | select(($cache[0][.id].version // -1) != .version)]' "$work/list.json" >"$work/stale.json"
      if [[ $(jq length "$work/stale.json") != 0 ]]; then
        jq -c . "$work/stale.json" | op item get - --format json >"$work/items.json"
        jq -r '[.id, ((.fields | map(select(.label == "token" or .label == "credential" or .label == "password") | select((.value // "") != "")) | sort_by(.label != "token"))[0].value // "" | @base64)] | @tsv' "$work/items.json" | hashed >"$work/hashes.tsv"
        jq -s --rawfile hashes "$work/hashes.tsv" --slurpfile cache "$cache" '
          ($hashes | split("\n") | map(select(length > 0) | split("\t") | {key: .[0], value: {exact: .[1], trimmed: .[2]}}) | from_entries) as $hash
          | $cache[0] + (map({key: .id, value: {
              title, version,
              token: any(.fields[]; .label == "token" and (.value // "") != ""),
              expires: (first(.fields[] | select(.label == "expires" and .type == "DATE") | .value | tonumber? | select(. > 0)) // null),
              hash: $hash[.id]
            }}) | from_entries)
        ' "$work/items.json" >"$work/cache.json"
        install -m 600 "$work/cache.json" "$cache"
      fi
      jq --slurpfile list "$work/list.json" 'with_entries(select(.key as $id | any($list[0][]; .id == $id)))' "$cache" >"$work/vault.json"

      doppler projects --json | jq -r '.[].id' | while read -r project; do
        doppler configs --project "$project" --json | jq -r --arg project "$project" '.[] | [$project, .name] | @tsv'
      done >"$work/configs.tsv"
      while IFS=$'\t' read -r project config; do
        doppler secrets download --project "$project" --config "$config" --no-file --format json \
          | jq -r --arg at "$project/$config" 'del(.DOPPLER_PROJECT, .DOPPLER_ENVIRONMENT, .DOPPLER_CONFIG) | to_entries[] | ["\($at) \(.key)", (.value | @base64)] | @tsv' \
          | hashed
      done <"$work/configs.tsv" >"$work/doppler.tsv"

      jq -r '.[].title' "$work/vault.json" | sort -u >"$work/vault-names"
      cut -f1 "$work/doppler.tsv" | cut -d' ' -f2 | sort -u >"$work/doppler-names"
      sort -u "$work/vault-names" "$work/doppler-names" >"$work/names"
      readers=()
      for path in ${lib.escapeShellArgs censusReaders}; do
        [[ ! -e $path ]] || readers+=("$path")
      done
      rg --no-messages -w -o -N -I -F -f "$work/names" -g '!*.md' -g '!.artifacts' "''${readers[@]}" | sort -u >"$work/read-names" || true

      {
        printf 'checked: %s, %s items in Tokens, %s Doppler names\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "$(wc -l <"$work/vault-names")" "$(wc -l <"$work/doppler-names")"
        printf 'no-token-field: %s\n' "$(jq -r '.[] | select(.token | not) | .title' "$work/vault.json" | sort | listed)"
        printf 'expires-within-30-days: %s\n' "$(jq -r '.[] | select(.expires != null and .expires <= now + 2592000) | "\(.title) \(.expires | strftime("%Y-%m-%d"))"' "$work/vault.json" | sort | listed)"
        printf 'no-expiry-date: %s\n' "$(jq -r '.[] | select(.expires == null) | .title' "$work/vault.json" | sort | listed)"
        printf 'only-1password: %s\n' "$(comm -23 "$work/vault-names" "$work/doppler-names" | listed)"
        printf 'only-doppler: %s\n' "$(comm -13 "$work/vault-names" "$work/doppler-names" | listed)"
        printf 'no-reader: %s\n' "$(comm -23 "$work/names" "$work/read-names" | listed)"
        printf 'value-differs: %s\n' "$(jq -r --rawfile doppler "$work/doppler.tsv" '
            (map({key: .title, value: .hash}) | from_entries) as $vault
            | $doppler | split("\n")[] | select(length > 0) | split("\t") | (.[0] | split(" ")) as [$at, $name]
            | select($vault[$name] != null and $vault[$name].exact != .[1])
            | "\($name) (\($at)\(if $vault[$name].trimmed == .[2] then ", trailing newline alone" else "" end))"
          ' "$work/vault.json" | sort | listed)"
      } >"$work/findings"
      install -m 600 "$work/findings" ${lib.escapeShellArg opCensus}
      awk -F': ' 'NR == 1 { print "secret-census: " $2; next } { printf "  %s %d\n", $1, ($2 == "") ? 0 : split($2, names, ", ") }' ${lib.escapeShellArg opCensus}
    '';
  };
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
  options.forge.secrets.templates = lib.mkOption {
    type = lib.types.attrsOf lib.types.lines;
    default = {};
    description = "Files a tool reads its credential from: path -> text with `{{ op://... }}` references, rendered at each activation by `op inject`, mode 600, outside the Nix store.";
  };

  options.forge.secrets.sessionCache = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = opCache;
    description = "Path of the op-injected session cache published at activation.";
  };

  config = {
    home = {
      packages = [pkgs._1password-cli-current pkgs.doppler secretCensus];

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

        # --- [SECRET_TEMPLATES]
        renderSecretTemplates = lib.hm.dag.entryAfter ["injectSecretsFromVault"] (lib.concatStrings (lib.mapAttrsToList (file: text: ''
            if [[ -v DRY_RUN ]]; then
              echo "op inject > ${file}"
            elif mkdir -p ${lib.escapeShellArg (dirOf file)} \
              && OP_SERVICE_ACCOUNT_TOKEN="$(<${lib.escapeShellArg opServiceAccount.file})" ${op} inject --force --file-mode 0600 -i ${pkgs.writeText (baseNameOf file) text} -o ${lib.escapeShellArg file} >/dev/null; then
              verboseEcho "Rendered ${file}"
            else
              echo "WARNING: ${file} was not rendered and keeps its previous content" >&2
            fi
          '')
          config.forge.secrets.templates));

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

        # --- [STORE_SHAPE]
        secretCensus = lib.hm.dag.entryAfter ["injectSecretsFromVault"] ''
          if [[ ! -v DRY_RUN ]]; then
            ${lib.getExe pkgs.doppler} flags disable env-warning >/dev/null 2>&1 || true
            ${lib.getExe secretCensus} || echo "secret-census: did not finish, ${opCensus} keeps its last findings" >&2
          fi
        '';

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
          [ "''${${stampName}:-}" = "@stamp@" ] || unset ${toString tokenNames}
          export ${stampName}="@stamp@"
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
