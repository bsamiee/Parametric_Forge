{
  config,
  host,
  launchdAgent,
  lib,
  pkgs,
  ...
}: let
  server = "https://ntfy.parametric-arsenal.cloud";
  gatus = "http://lucky:8080";
  clientConfig = "${config.home.homeDirectory}/Library/Application Support/ntfy/client.yml";
  inbox = "${config.xdg.stateHome}/taildrop";
  zellij = lib.getExe config.programs.zellij.package;
  agentNotify = pkgs.writeShellApplication {
    name = "agent-notify";
    runtimeInputs = [pkgs.jq pkgs.ntfy-sh];
    text = ''
      harness="''${1:?usage: agent-notify <harness> [message] [ntfy publish options]; without a message the body is stdin}"
      buttons=()
      if [[ -n "''${ZELLIJ_SESSION_NAME:-}" && -n "''${ZELLIJ_PANE_ID:-}" ]]; then
        session="$(jq -rn --arg session "$ZELLIJ_SESSION_NAME" '$session | @uri')"
        buttons=(--actions "view, Reply, shortcuts://run-shortcut?name=Agent%20Reply&input=text&text=$session%2F$ZELLIJ_PANE_ID; view, Terminal, https://${host.tailnet.node}:${config.forge.zellij.web.tailnetPort}/$session")
      fi
      exec ntfy publish --quiet "''${buttons[@]}" "''${@:3}" "agent-$harness" ''${2:+"$2"}
    '';
  };
  agentReply = pkgs.writeShellApplication {
    name = "agent-reply";
    runtimeInputs = [pkgs.jq];
    text = ''
      target="''${NTFY_TITLE:?agent-reply runs under ntfy subscribe: NTFY_TITLE is <session>/<pane>, NTFY_MESSAGE the text}"
      session="''${target%%/*}"
      pane="''${target##*/}"
      if [[ ! $target =~ ^[A-Za-z0-9._][A-Za-z0-9._-]*/[0-9]+$ || ! $NTFY_MESSAGE =~ ^[^[:cntrl:]!][^[:cntrl:]]*$ ]] || ((''${#NTFY_MESSAGE} > 2000)) \
        || ! ${zellij} --session "$session" action list-panes --json --all 2>/dev/null \
          | jq -e --argjson pane "$pane" 'any(.[]; (.is_plugin | not) and .id == $pane and .attention.detail.app != null)' >/dev/null; then
        printf '%s dropped: the title names no agent pane, or the text is not one printable line of at most 2000 characters\n' "$(date +%FT%T)"
        exit 0
      fi
      ${zellij} --session "$session" action write-chars --pane-id "terminal_$pane" "$NTFY_MESSAGE"
      ${zellij} --session "$session" action write --pane-id "terminal_$pane" 13
    '';
  };
  agentSessions = pkgs.writeShellApplication {
    name = "agent-sessions";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.jq pkgs.ntfy-sh];
    text = ''
      state=${lib.escapeShellArg "${config.xdg.stateHome}/agent-sessions"}
      panes="$(${zellij} list-sessions --short --no-formatting 2>/dev/null | while read -r session; do
        ${zellij} --session "$session" action list-panes --json --all 2>/dev/null \
          | jq -r --arg session "$session" '.[] | select(.is_plugin | not) | select(.attention.detail.app != null) | "\($session)/\(.id) \(.title)"' 2>/dev/null || true
      done)"
      if [[ "$panes" != "$(cat "$state" 2>/dev/null)" || -n "$(find "$state" -mmin +720 2>/dev/null)" ]]; then
        ntfy publish --quiet sessions "''${panes:-none}"
        printf '%s\n' "$panes" >"$state"
      fi
    '';
  };
  phoneSend = pkgs.writeShellApplication {
    name = "phone-send";
    text = ''
      exec ${config.forge.tailnet.cli} file cp "''${@:?usage: phone-send <file>...; Taildrop to ${host.tailnet.phone}, files land in the Files app}" ${host.tailnet.phone}:
    '';
  };
  heartbeat = pkgs.writeShellApplication {
    name = "gatus-heartbeat";
    runtimeInputs = [pkgs.xh];
    text = ''
      key="''${1:?usage: gatus-heartbeat <key> <command> [args]; runs the command, reports its result to Gatus, exits with its status}"
      shift
      status=0
      "$@" || status=$?
      if [[ -z "''${GATUS_HEARTBEAT_TOKEN:-}" && -f ${lib.escapeShellArg config.forge.secrets.sessionCache} ]]; then
        # shellcheck source=/dev/null
        . ${lib.escapeShellArg config.forge.secrets.sessionCache}
      fi
      report=("success==true")
      ((status == 0)) || report=("success==false" "error==exit $status")
      xh --ignore-stdin --quiet --timeout 10 POST "${gatus}/api/v1/endpoints/$key/external" \
        "''${report[@]}" "duration==''${SECONDS}s" "Authorization:Bearer ''${GATUS_HEARTBEAT_TOKEN:-}" \
        || echo "gatus-heartbeat: $key not reported" >&2
      exit "$status"
    '';
  };
  maintenance = pkgs.writeShellApplication {
    name = "mac-maintenance";
    runtimeInputs = [config.programs.nh.package pkgs.uv];
    text = ''
      uv cache prune
      nh clean all --keep 5 --keep-since 3d --no-gc
    '';
  };
in {
  options.forge.monitoring.heartbeat = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    default = heartbeat;
    description = "Runs a job and reports its result to the Gatus heartbeat key named first.";
  };

  config = {
    home.packages = [pkgs.ntfy-sh agentNotify heartbeat phoneSend];

    # --- [NTFY_CLIENT]
    forge.secrets.templates.${clientConfig} = ''
      default-host: ${server}
      default-token: {{ op://Tokens/NTFY_OWNER_TOKEN/token }}
      subscribe:
        - topic: reply
          command: ${lib.getExe agentReply}
    '';

    home.activation.restartPhoneReplies = lib.hm.dag.entryAfter ["renderSecretTemplates"] ''
      applied=${lib.escapeShellArg "${config.xdg.stateHome}/ntfy-reply.applied"}
      rendered="$(/usr/bin/shasum -a 256 <${lib.escapeShellArg clientConfig} 2>/dev/null || true)"
      if [[ -n "$rendered" && "$rendered" != "$(cat "$applied" 2>/dev/null || true)" ]]; then
        run /bin/launchctl kickstart -k "gui/$UID/${config.launchd.agents.ntfy-reply.config.Label}" || true
        printf '%s\n' "$rendered" >"$applied"
      fi
    '';

    launchd.agents = {
      # --- [PHONE_REPLIES]
      ntfy-reply = launchdAgent {
        name = "ntfy-reply";
        argv = [(lib.getExe pkgs.ntfy-sh) "subscribe" "--from-config"];
        RunAtLoad = true;
        KeepAlive.PathState.${clientConfig} = true;
      };

      # --- [PANE_LIST]
      agent-sessions = launchdAgent {
        name = "agent-sessions";
        argv = [(lib.getExe agentSessions)];
        StartInterval = 60;
      };

      # --- [PHONE_INBOX]
      taildrop-inbox = launchdAgent {
        name = "taildrop-inbox";
        argv = ["/bin/sh" "-c" "/bin/mkdir -p \"$1\" && \"$0\" file get --loop --conflict=rename \"$1\"" config.forge.tailnet.cli inbox];
        RunAtLoad = true;
        KeepAlive = true;
      };

      # --- [WEEKLY_MAINTENANCE]
      mac-maintenance = launchdAgent {
        name = "mac-maintenance";
        argv = [(lib.getExe heartbeat) "mac-jobs_mac-maintenance" (lib.getExe maintenance)];
        StartCalendarInterval = [
          {
            Weekday = 0;
            Hour = 4;
            Minute = 30;
          }
        ];
      };
    };
  };
}
