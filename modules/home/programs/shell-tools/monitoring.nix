{
  config,
  host,
  launchdAgent,
  lib,
  pkgs,
  ...
}: let
  server = "https://ntfy.parametric-arsenal.cloud";
  clientConfig = "${config.xdg.configHome}/ntfy/client.yml";
  inbox = "${config.xdg.stateHome}/taildrop";
  zellij = lib.getExe config.programs.zellij.package;
  sessionToken = name: ''
    if [[ -z "''${${name}:-}" && -f ${lib.escapeShellArg config.forge.secrets.sessionCache} ]]; then
      # shellcheck source=/dev/null
      . ${lib.escapeShellArg config.forge.secrets.sessionCache}
    fi
  '';
  agentNotify = pkgs.writeShellApplication {
    name = "agent-notify";
    runtimeInputs = [pkgs.jq pkgs.ntfy-sh];
    text = ''
      harness="''${1:?usage: agent-notify <harness> [message] [ntfy publish options]; without a message the body is stdin}"
      buttons=()
      if [[ -n "''${ZELLIJ_SESSION_NAME:-}" && -n "''${ZELLIJ_PANE_ID:-}" ]]; then
        target="$(jq -rn --arg target "$ZELLIJ_SESSION_NAME/$ZELLIJ_PANE_ID" '$target | @uri')"
        buttons=(--actions "view, Reply, shortcuts://run-shortcut?name=Agent%20Reply&input=text&text=$target; view, Terminal, https://${config.forge.tailnet.node}:${lib.head (lib.attrNames config.forge.tailnet.serve)}/$ZELLIJ_SESSION_NAME")
      fi
      exec ntfy publish --config ${lib.escapeShellArg clientConfig} --quiet "''${buttons[@]}" "''${@:3}" "agent-$harness" ''${2:+"$2"}
    '';
  };
  agentReply = pkgs.writeShellApplication {
    name = "agent-reply";
    text = ''
      target="''${NTFY_TITLE:?agent-reply runs under ntfy subscribe: NTFY_TITLE is <session>/<pane>, NTFY_MESSAGE the text}"
      ${zellij} --session "''${target%%/*}" action write-chars --pane-id "terminal_''${target##*/}" "$NTFY_MESSAGE"
      ${zellij} --session "''${target%%/*}" action write --pane-id "terminal_''${target##*/}" 13
    '';
  };
  agentSessions = pkgs.writeShellApplication {
    name = "agent-sessions";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.jq pkgs.ntfy-sh];
    text = ''
      state=${lib.escapeShellArg "${config.xdg.stateHome}/agent-sessions"}
      panes="$(${zellij} list-sessions --short --no-formatting 2>/dev/null | while read -r session; do
        ${zellij} --session "$session" action list-panes --json --all 2>/dev/null \
          | jq -r --arg session "$session" '.[] | select(.is_plugin | not) | select(.attention.detail.app != null) | "\($session)/\(.id) \(.title)"'
      done)"
      if [[ "$panes" != "$(cat "$state" 2>/dev/null)" || -n "$(find "$state" -mmin +720 2>/dev/null)" ]]; then
        ntfy publish --config ${lib.escapeShellArg clientConfig} --quiet sessions "''${panes:-none}"
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
      ${sessionToken "GATUS_HEARTBEAT_TOKEN"}
      report=("success==true")
      ((status == 0)) || report=("success==false" "error==exit $status")
      xh --ignore-stdin --quiet --timeout 10 POST "${config.forge.monitoring.gatus}/api/v1/endpoints/$key/external" \
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
  options.forge.monitoring = {
    gatus = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "http://lucky:8080";
      description = "Gatus on the tailnet: status API and heartbeat endpoint, no login.";
    };
    heartbeat = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = heartbeat;
      description = "Runs a job and reports its result to the Gatus heartbeat key named first.";
    };
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

    launchd.agents = {
      # --- [PHONE_REPLIES]
      ntfy-reply = launchdAgent {
        name = "ntfy-reply";
        argv = [(lib.getExe pkgs.ntfy-sh) "subscribe" "--config" clientConfig "--from-config"];
        RunAtLoad = true;
        KeepAlive = true;
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
