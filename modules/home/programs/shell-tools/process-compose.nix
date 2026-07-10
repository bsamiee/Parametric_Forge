# Title         : process-compose.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/process-compose.nix
# ----------------------------------------------------------------------------
# Non-container process orchestration for project-local service meshes; the package row lives in the owner table. Container-tools owns the
# container/Kubernetes axis and launchd owns durable machine services; process-compose is a project-owned foreground runner, so shell-tools owns it.

{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette roles;
  yamlFormat = pkgs.formats.yaml {};

  # forge-pc: detached project mesh over one deterministic per-project UDS. The server default socket embeds the PID, so a detached server is
  # unaddressable later; pinning the socket to a project hash makes every client verb (state/logs/attach/down) reattachable and JSON-first.
  forgePc = pkgs.writeShellApplication {
    name = "forge-pc";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.process-compose];
    text = ''
      usage() {
        printf 'usage: forge-pc up [ARGS...] | down | attach | state | ports PROC | logs PROC | restart PROC | graph | doctor [--json]\n' >&2
        exit 64
      }
      verb="''${1:-}"; shift || true
      [ -n "$verb" ] || usage

      sock_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/process-compose"
      mkdir -p "$sock_dir"
      project_id="$(printf '%s' "$PWD" | cksum | cut -d' ' -f1)"
      sock="$sock_dir/pc-$project_id.sock"
      client=(process-compose -U -u "$sock")

      case "$verb" in
        up)
          # Detached + ordered shutdown; probes/restart policy stay project-owned in process-compose.yaml.
          exec process-compose up -U -u "$sock" --detached --ordered-shutdown "$@"
          ;;
        down) exec "''${client[@]}" down ;;
        attach) exec "''${client[@]}" attach ;;
        state) exec "''${client[@]}" process list -o json ;;
        ports) exec "''${client[@]}" process ports "''${1:?usage: forge-pc ports PROC}" ;;
        logs) exec "''${client[@]}" process logs "''${1:?usage: forge-pc logs PROC}" ;;
        restart) exec "''${client[@]}" process restart "''${1:?usage: forge-pc restart PROC}" ;;
        graph) exec process-compose graph "$@" ;;
        doctor)
          live=0
          if [ -S "$sock" ] && "''${client[@]}" project state >/dev/null 2>&1; then
            live=1
          fi
          if [ "''${1:-}" = "--json" ]; then
            # Same receipt envelope as the estate JSONL rails: ts + surface + payload + result, one grammar for every doctor.
            TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
            jq -cn --arg ts "$ts" --arg project "''${PWD##*/}" --arg sock "$sock" \
              --argjson live "$([ "$live" = 1 ] && printf true || printf false)" \
              '{ts: $ts, surface: "forge-pc-doctor", project: $project,
                socket: $sock, live: $live,
                result: (if $live then "ok" else "down" end)}'
          elif [ "$live" = 1 ]; then
            printf '[OK]   %s live on %s\n' "''${PWD##*/}" "$sock"
          else
            printf '[DOWN] %s no server on %s\n' "''${PWD##*/}" "$sock"
          fi
          [ "$live" = 1 ] || exit 1
          ;;
        *) usage ;;
      esac
    '';
  };

  # Cockpit: the machine-scoped operator mesh — signed-event inbox, receipt tailer, MCP fleet drift probe — as one foreground process-compose
  # project. Probes are processes with restart cadence, never launchd agents; the webhook port projects from the webhook.nix session variable.
  webhookPort = lib.toInt config.home.sessionVariables.WEBHOOK_PORT;
  receiptsFile = "${config.xdg.stateHome}/forge-webhook/receipts.jsonl";

  cockpitConfig = {
    version = "0.5";
    processes = {
      inbox = {
        command = "forge-webhook";
        readiness_probe = {
          http_get = {
            host = "127.0.0.1";
            port = webhookPort;
            path = "/hooks/ping";
          };
          initial_delay_seconds = 1;
          period_seconds = 10;
          failure_threshold = 3;
        };
        availability = {
          restart = "always";
          backoff_seconds = 2;
        };
      };
      inbox-tail = {
        command = "touch ${receiptsFile} && exec tail -n 40 -F ${receiptsFile}";
        depends_on.inbox.condition = "process_started";
        availability = {
          restart = "always";
          backoff_seconds = 2;
        };
      };
      fleet-drift = {
        command = "forge-mcp drift";
        availability = {
          restart = "always";
          backoff_seconds = 900;
        };
      };
    };
  };

  cockpitYaml = yamlFormat.generate "forge-cockpit" cockpitConfig;

  forgeCockpit = pkgs.writeShellApplication {
    name = "forge-cockpit";
    runtimeInputs = [pkgs.coreutils pkgs.process-compose];
    text = ''
      sock_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/process-compose"
      mkdir -p "$sock_dir"
      exec process-compose up -f ${cockpitYaml} -U -u "$sock_dir/pc-cockpit.sock" --ordered-shutdown "$@"
    '';
  };

  # theme.yaml backs the TUI "Custom Style" selector entry.
  forgeStyle.style = {
    body = {
      fgColor = roles.text.primary.hex;
      bgColor = roles.surface.base.hex;
      secondaryTextColor = roles.text.muted.hex;
      tertiaryTextColor = roles.accent.primary.hex;
      borderColor = roles.surface.selected.hex;
    };
    stat_table = {
      keyFgColor = roles.accent.structural.hex;
      valueFgColor = roles.text.primary.hex;
      bgColor = roles.surface.base.hex;
      logoColor = roles.accent.secondary.hex;
    };
    proc_table = {
      fgColor = roles.text.primary.hex;
      fgWarning = roles.state.warning.hex;
      fgPending = roles.text.muted.hex;
      fgCompleted = roles.state.success.hex;
      fgError = roles.state.danger.hex;
      bgColor = roles.surface.base.hex;
      headerFgColor = roles.accent.primary.hex;
    };
    help = {
      fgColor = roles.text.primary.hex;
      keyColor = roles.accent.primary.hex;
      hlColor = roles.state.success.hex;
      buttonBgColor = palette.comment.hex;
      categoryFgColor = roles.accent.structural.hex;
    };
    dialog = {
      fgColor = roles.text.primary.hex;
      bgColor = roles.surface.raised.hex;
      contrastBgColor = roles.surface.overlay.hex;
      attentionBgColor = roles.state.attention.hex;
      buttonFgColor = roles.text.inverse.hex;
      buttonBgColor = palette.comment.hex;
      buttonFocusFgColor = roles.text.inverse.hex;
      buttonFocusBgColor = roles.accent.primary.hex;
      labelFgColor = roles.state.warning.hex;
      fieldFgColor = roles.text.primary.hex;
      fieldBgColor = roles.surface.selected.hex;
    };
  };
in {
  home.packages = [forgePc forgeCockpit];

  xdg.configFile."process-compose/theme.yaml".source = yamlFormat.generate "process-compose-theme" forgeStyle;

  # settings.yaml is TUI-mutated state (theme/sort auto-save); seed the custom style selection once, never overwrite later user edits.
  home.activation.seedProcessComposeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    settings="${config.xdg.configHome}/process-compose/settings.yaml"
    if [ ! -f "$settings" ]; then
      run mkdir -p "${config.xdg.configHome}/process-compose"
      run sh -c "printf 'theme: Custom Style\n' > \"$settings\""
    fi
  '';
}
