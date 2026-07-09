# Title         : ssh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/ssh.nix
# ----------------------------------------------------------------------------
# SSH client configuration with GitHub integration and VPS loopback tunnels.
# One tunnel row projects everything: interactive host block, transport-only
# tunnel block, launchd agent, and service-health receipts. A future VPS is a
# new row here, never a new agent module.
{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  # Probe classes drive the health receipts: pg (pg_isready), http (GET path),
  # none (forward only, bind-checked but never service-probed).
  vpsTunnels = {
    maghz = {
      user = "maghz-agent";
      hostName = "31.97.131.41";
      forwards = [
        {
          port = 9000;
          service = "webhook";
          probe = "none";
        }
        {
          port = 6800;
          service = "aria2-rpc";
          probe = "none";
        }
        {
          port = 1455;
          service = "codex-oauth";
          probe = "none";
        }
        {
          port = 15435;
          service = "postgres";
          probe = "pg";
        }
        {
          port = 11434;
          service = "ollama";
          probe = "http";
          path = "/api/version";
        }
        {
          port = 5678;
          service = "n8n";
          probe = "http";
          path = "/healthz";
        }
        {
          # 8788: the Jupyter loopback owns 8888 on both ends of the tunnel.
          port = 8788;
          service = "atuin";
          probe = "http";
          path = "/";
        }
      ];
    };
  };

  forwardsFor = tunnel:
    map (f: {
      bind.port = f.port;
      host.address = "localhost";
      host.port = f.port;
    })
    tunnel.forwards;

  # Interactive operator hosts: `ssh maghz` opens a plain session. Forwards
  # belong solely to the launchd tunnel agent — an interactive mux that also
  # binds them would hold the loopback ports and starve the durable owner.
  interactiveHosts = lib.mapAttrs' (name: tunnel:
    lib.nameValuePair "${name}-vps ${name}" {
      User = tunnel.user;
      HostName = tunnel.hostName;
      IdentitiesOnly = true;
      AddKeysToAgent = "yes";
    })
  vpsTunnels;

  # Transport-only tunnel hosts: fail-fast forwards + tight keepalives; the
  # supervisor owns lifecycle, launchd owns restart policy.
  tunnelHosts = lib.mapAttrs' (name: tunnel:
    lib.nameValuePair "${name}-tunnel" {
      User = tunnel.user;
      HostName = tunnel.hostName;
      IdentitiesOnly = true;
      AddKeysToAgent = "yes";
      BatchMode = true;
      Compression = false;
      # ControlPath none: ControlMaster no alone still JOINS an existing mux,
      # whose master then retains the forwards after the supervisor dies —
      # the port-conflict loop. The transport must never touch the estate mux.
      ControlMaster = "no";
      ControlPath = "none";
      ExitOnForwardFailure = true;
      LocalForward = forwardsFor tunnel;
      ServerAliveInterval = 15;
      ServerAliveCountMax = 3;
      SessionType = "none";
      StdinNull = true;
      TCPKeepAlive = false;
    })
  vpsTunnels;

  tunnelRowJson = name: tunnel:
    pkgs.writeText "vps-tunnel-${name}.json" (builtins.toJSON {
      inherit name;
      sshHost = "${name}-tunnel";
      inherit (tunnel) forwards;
    });

  # Per-row identity bundle: Login Items & Extensions resolves the agent's
  # AssociatedBundleIdentifiers to "<Name> VPS Tunnel" instead of the "/bin/sh"
  # basename home-manager's mutateConfig writes into ProgramArguments[0].
  tunnelTitle = name: "${lib.toSentenceCase name} VPS Tunnel";
  tunnelBundleId = name: "com.parametric-forge.${name}-vps-tunnel";
  tunnelInfoPlist = name: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key>
      <string>${tunnelBundleId name}</string>
      <key>CFBundleName</key>
      <string>${tunnelTitle name}</string>
      <key>CFBundleDisplayName</key>
      <string>${tunnelTitle name}</string>
      <key>CFBundleVersion</key>
      <string>1</string>
      <key>CFBundleShortVersionString</key>
      <string>1.0</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>LSUIElement</key>
      <true/>
      <key>LSBackgroundOnly</key>
      <true/>
    </dict>
    </plist>
  '';

  # Health-gated supervisor: spawns ssh -N, proves every local bind, then
  # emits service-health receipts on state transitions. Restart-worthy states
  # are transport-scoped only (port-conflict, vps-unreachable, bind-failed,
  # bind-lost) — service-down is receipted, never restarted: a local restart
  # cannot fix a remote service, and churn would mask real VPS outages.
  tunnelSupervisor = pkgs.writeShellApplication {
    name = "forge-vps-tunnel";
    runtimeInputs = [pkgs.coreutils pkgs.openssh pkgs.curl pkgs.jq pkgs.lsof];
    text = ''
      row_file="$1"
      IFS=$'\t' read -r name ssh_host < <(jq -r '[.name, .sshHost] | @tsv' "$row_file")
      receipts="''${FORGE_TUNNEL_RECEIPTS:-$HOME/Library/Logs/forge-$name-vps-tunnel.receipts.log}"
      interval="''${FORGE_TUNNEL_PROBE_INTERVAL:-60}"
      bind_grace="''${FORGE_TUNNEL_BIND_GRACE:-20}"
      bind_fail_max="''${FORGE_TUNNEL_BIND_FAILS:-3}"

      # Knobs are positive integers or the defaults — a stray override must
      # never crash the supervisor into a receiptless restart loop.
      case "$interval" in "" | *[!0-9]* | 0) interval=60 ;; esac
      case "$bind_grace" in "" | *[!0-9]* | 0) bind_grace=20 ;; esac
      case "$bind_fail_max" in "" | *[!0-9]* | 0) bind_fail_max=3 ;; esac

      mapfile -t ports < <(jq -r '.forwards[].port' "$row_file")

      # Dual receipt: TSV stays the human/log contract, the JSONL sibling is
      # the agent contract (same envelope keys).
      emit() {
        mkdir -p "$(dirname "$receipts")"
        local ts detail
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        printf 'ts=%s\ttunnel=%s\tstate=%s\t%s\n' "$ts" "$name" "$1" "''${2:-}" | tee -a "$receipts"
        # TSV rows carry a detail= column prefix; the JSONL key already names
        # the field, so the prefix is stripped rather than doubled.
        detail="''${2:-}"
        detail="''${detail#detail=}"
        jq -cn --arg ts "$ts" --arg tunnel "$name" --arg state "$1" --arg detail "$detail" \
          '{ts: $ts, surface: "vps-tunnel", tunnel: $tunnel, state: $state, detail: $detail}' \
          >>"''${receipts%.log}.jsonl"
      }

      port_open() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }

      # Predicate-to-state projection: any probe command becomes ok|down.
      state_of() { if "$@" >/dev/null 2>&1; then echo ok; else echo down; fi; }

      binds_ok() {
        local p
        for p in "''${ports[@]}"; do port_open "$p" || return 1; done
      }

      # One receipt field per probed service: svc=ok|down through the forward.
      service_vector() {
        local svc probe port path state
        while IFS=$'\t' read -r svc probe port path; do
          case "$probe" in
            pg) state="$(state_of "${pkgs.postgresql_18}/bin/pg_isready" -q -h 127.0.0.1 -p "$port" -t 5)" ;;
            http) state="$(state_of curl -fsS --max-time 5 -o /dev/null "http://127.0.0.1:$port$path")" ;;
            *) state="$(state_of port_open "$port")" ;;
          esac
          printf '%s=%s ' "$svc" "$state"
        done < <(jq -r '.forwards[] | select(.probe != "none") | [.service, .probe, (.port | tostring), (.path // "")] | @tsv' "$row_file")
      }

      # A row with zero forwards proves nothing — refuse the vacuous up state.
      if [ "''${#ports[@]}" -eq 0 ]; then
        emit row-invalid "detail=no forward ports in $row_file"
        exit 1
      fi

      # Loopback parity guard: a port accepting before ssh spawns belongs to
      # another owner (compose local mode) — receipt the truth, never let the
      # collision masquerade as vps-unreachable or bind-failed.
      conflicts=""
      for p in "''${ports[@]}"; do port_open "$p" && conflicts="$conflicts $p"; done
      if [ -n "$conflicts" ]; then
        # Holder identification at the receipt separates routine (colima local
        # parity mode) from regression (a shared ssh mux retaining forwards).
        read -ra cports <<<"$conflicts"
        holders="$(for p in "''${cports[@]}"; do
          lsof -nP -iTCP:"$p" -sTCP:LISTEN 2>/dev/null | awk -v port="$p" 'NR>1 {print port":"$1":"$2}'
        done | sort -u | paste -sd, -)"
        emit port-conflict "detail=already bound before spawn:$conflicts holders=''${holders:-unknown}"
        exit 1
      fi

      # Traps precede the spawn: TERM in the spawn window must still reap ssh,
      # and untrapped SIGTERM would skip the EXIT trap on launchd unload.
      ssh_pid=""
      trap '{ [ -n "$ssh_pid" ] && kill "$ssh_pid" 2>/dev/null && wait "$ssh_pid" 2>/dev/null; } || true' EXIT
      trap 'exit 143' TERM INT
      ssh -N "$ssh_host" &
      ssh_pid=$!

      # Bind proof: ssh death before binds is vps-unreachable; a live ssh whose
      # forwards never accept within the grace window is bind-failed.
      deadline=$((SECONDS + bind_grace))
      until binds_ok; do
        if ! kill -0 "$ssh_pid" 2>/dev/null; then
          emit vps-unreachable "detail=ssh exited before local binds"
          exit 1
        fi
        if [ "$SECONDS" -ge "$deadline" ]; then
          emit bind-failed "detail=forwards not accepting within ''${bind_grace}s"
          exit 1
        fi
        sleep 1
      done

      last=""
      bind_fails=0
      while :; do
        if ! kill -0 "$ssh_pid" 2>/dev/null; then
          emit vps-unreachable "detail=ssh transport exited"
          exit 1
        fi
        if binds_ok; then
          bind_fails=0
          vector="$(service_vector)"
          current="services=''${vector% }"
          if [ "$current" != "$last" ]; then
            emit up "$current"
            last="$current"
          fi
        else
          # Hysteresis: only consecutive bind losses restart the transport.
          bind_fails=$((bind_fails + 1))
          if [ "$bind_fails" -ge "$bind_fail_max" ]; then
            emit bind-lost "detail=$bind_fails consecutive bind probes failed"
            exit 1
          fi
        fi
        # Backgrounded sleep keeps the interval interruptible by TERM/INT.
        sleep "$interval" &
        wait "$!" || true
      done
    '';
  };
in {
  # Host rows projected for downstream consumers (WezTerm ssh_domains,
  # pickers): transport facts only, forwards reduced to service/port pairs.
  options.forge.ssh.hosts = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    default =
      lib.mapAttrs (name: tunnel: {
        inherit name;
        inherit (tunnel) user hostName;
        aliases = ["${name}-vps" name];
        tunnelHost = "${name}-tunnel";
        forwards = map (f: {inherit (f) port service;}) tunnel.forwards;
      })
      vpsTunnels;
    description = "SSH estate host rows: interactive aliases, transport identity, declared forwards.";
  };

  config =
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false; # Explicitly disable default config to suppress warning

        settings =
          {
            # --- GitHub Configuration -------------------------------------------
            "github.com" = {
              User = "git";
              HostName = "github.com";
              IdentitiesOnly = true;
              AddKeysToAgent = "yes";
            };

            # --- Default Optimizations for All Hosts ----------------------------
            "*" =
              lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
                # 1Password's stable agent socket is the identity source on Darwin;
                # Linux hosts authenticate inbound through authorized keys.
                IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
              }
              // {
                # Connection multiplexing for performance
                ControlMaster = "auto";
                ControlPath = "${config.home.homeDirectory}/.ssh/sockets/%C";
                ControlPersist = "10m";

                # Keep-alive settings
                ServerAliveInterval = 60;
                ServerAliveCountMax = 3;

                # Security and convenience
                AddKeysToAgent = "yes";
                HashKnownHosts = true;

                # Performance
                Compression = true;
              };
          }
          // interactiveHosts
          // tunnelHosts;
      };

      home.file = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin (
        lib.mapAttrs' (
          name: _:
            lib.nameValuePair
            "Applications/${tunnelTitle name}.app/Contents/Info.plist"
            {text = tunnelInfoPlist name;}
        )
        vpsTunnels
      );

      home.activation.registerVpsTunnelApps = lib.hm.dag.entryAfter ["linkGeneration"] ''
        lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
        ${lib.concatMapStrings (name: ''
          app="$HOME/Applications/${tunnelTitle name}.app"
          if [ -d "$app" ] && [ -x "$lsregister" ]; then
            "$lsregister" -f "$app" || true
          fi
        '') (builtins.attrNames vpsTunnels)}
      '';

      # Durable per-row tunnel agents: remote-primary mode kickstarts them; local
      # parity mode boots them out before compose binds the same loopback ports.
      # KeepAlive=true implies RunAtLoad per launchd.plist(5). One row registry
      # projects both supervisors: launchd (Darwin) and lingering systemd user
      # services (Linux) run the identical health-gated supervisor.
      launchd.agents = lib.mapAttrs' (name: tunnel:
        lib.nameValuePair "${name}-vps-tunnel" {
          enable = true;
          config = {
            Label = "com.parametric-forge.${name}-vps-tunnel";
            ProgramArguments = ["${tunnelSupervisor}/bin/forge-vps-tunnel" "${tunnelRowJson name tunnel}"];
            KeepAlive = true;
            ThrottleInterval = 30;
            ProcessType = "Background";
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/forge-${name}-vps-tunnel.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/forge-${name}-vps-tunnel.log";
            AssociatedBundleIdentifiers = [(tunnelBundleId name)];
          };
        })
      vpsTunnels;
    }
    # Static host gate: config attr names must never depend on pkgs (fixpoint).
    // lib.optionalAttrs (host.os == "nixos") {
      systemd.user.services = lib.mapAttrs' (name: tunnel:
        lib.nameValuePair "${name}-vps-tunnel" {
          Unit.Description = "Forge VPS tunnel ${name}";
          Service = {
            ExecStart = "${tunnelSupervisor}/bin/forge-vps-tunnel ${tunnelRowJson name tunnel}";
            Environment = ["FORGE_TUNNEL_RECEIPTS=%h/.local/state/forge-tunnels/${name}-vps-tunnel.receipts.log"];
            Restart = "always";
            RestartSec = 30;
          };
          Install.WantedBy = ["default.target"];
        })
      vpsTunnels;
    };
}
