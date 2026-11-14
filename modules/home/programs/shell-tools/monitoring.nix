{
  config,
  launchdAgent,
  lib,
  pkgs,
  ...
}: let
  clientConfig = "${config.xdg.configHome}/ntfy/client.yml";
  sessionToken = name: ''
    if [[ -z "''${${name}:-}" && -f ${lib.escapeShellArg config.forge.secrets.sessionCache} ]]; then
      # shellcheck source=/dev/null
      . ${lib.escapeShellArg config.forge.secrets.sessionCache}
    fi
  '';
  agentNotify = pkgs.writeShellApplication {
    name = "agent-notify";
    runtimeInputs = [pkgs.ntfy-sh];
    text = ''
      harness="''${1:?usage: agent-notify <harness> [message] [ntfy publish options]; without a message the body is stdin}"
      ${sessionToken "NTFY_TOKEN"}
      exec ntfy publish --config ${lib.escapeShellArg clientConfig} --quiet "''${@:3}" "agent-$harness" ''${2:+"$2"}
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
    runtimeInputs = [pkgs.uv];
    text = ''
      uv cache prune
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
    home.packages = [pkgs.ntfy-sh agentNotify heartbeat];

    # --- [NTFY_CLIENT]
    xdg.configFile."ntfy/client.yml".text = ''
      default-host: https://ntfy.parametric-arsenal.cloud
    '';

    # --- [WEEKLY_MAINTENANCE]
    launchd.agents.mac-maintenance = launchdAgent {
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
}
