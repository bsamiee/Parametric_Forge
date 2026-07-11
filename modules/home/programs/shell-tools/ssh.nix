# Title         : ssh.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/ssh.nix
# ----------------------------------------------------------------------------
# SSH client configuration with GitHub integration and VPS loopback tunnels. One tunnel row projects everything: interactive host block,
# transport-only tunnel block, launchd tunnel agent, rclone mount agents, service-health receipts, and the remote-surface rows every consumer
# folds (WezTerm SSH domains, Yazi VFS, workspace picker). A future VPS is a new row here, never a new agent module.
{
  config,
  host,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;

  # One identity agent for every remote surface: ssh client, WezTerm mux, Yazi VFS, and the rclone mount lane all pin this socket — the ambient
  # SSH_AUTH_SOCK is the identity-less Apple launchd agent.
  identityAgent = "${homeDir}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  mountRoot = "${homeDir}/Volumes";

  # Probe classes drive the health receipts: pg (pg_isready), http (GET path), none (forward only, bind-checked but never service-probed). Mount
  # rows are the F12 mount-policy vocabulary: path (remote, "" = user home), readOnly, and cache posture (off|minimal|writes|full) — cache sinks
  # ONLY into the rclone lane; Yazi's ServiceSftp has no cache knob by design.
  vpsTunnels = {
    maghz = {
      user = "maghz-agent";
      hostName = "31.97.131.41";
      mounts = [
        {
          name = "home";
          path = "";
          readOnly = true;
          cache = "off";
        }
      ];
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
          port = 8788; # Jupyter owns 8888 on both tunnel ends
          service = "atuin";
          probe = "http";
          path = "/";
        }
        {
          port = 2586;
          service = "ntfy";
          probe = "http";
          path = "/v1/health";
        }
      ];
    };
  };

  # Supervisors project only onto client hosts: a self-named row would tunnel the machine to itself and flap on port-conflict.
  clientTunnels = lib.filterAttrs (name: _: name != host.name) vpsTunnels;

  forwardsFor = tunnel:
    map (f: {
      bind.port = f.port;
      host.address = "localhost";
      host.port = f.port;
    })
    tunnel.forwards;

  # Interactive operator hosts: `ssh maghz` opens a plain session. Forwards belong solely to the launchd tunnel agent — an interactive mux that
  # also binds them would hold the loopback ports and starve the durable owner.
  interactiveHosts = lib.mapAttrs' (name: tunnel:
    lib.nameValuePair "${name}-vps ${name}" {
      User = tunnel.user;
      HostName = tunnel.hostName;
      IdentitiesOnly = true;
      AddKeysToAgent = "yes";
    })
  vpsTunnels;

  # Transport-only tunnel hosts: fail-fast forwards + tight keepalives; the supervisor owns lifecycle, launchd owns restart policy.
  tunnelHosts = lib.mapAttrs' (name: tunnel:
    lib.nameValuePair "${name}-tunnel" {
      User = tunnel.user;
      HostName = tunnel.hostName;
      IdentitiesOnly = true;
      AddKeysToAgent = "yes";
      BatchMode = true;
      Compression = false;
      # ControlPath none: ControlMaster no alone still JOINS an existing mux, whose master then retains the forwards after the supervisor dies —
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

  # (host, mount) pairs on client hosts: each pair projects one supervisor agent, one receipt log, one receipt-registry row, and one mountpoint.
  mountPairs = lib.concatLists (lib.mapAttrsToList (
      name: tunnel:
        map (m: {
          inherit name m;
          inherit (tunnel) user hostName;
          agent = "${name}-mount-${m.name}";
          mountpoint = "${mountRoot}/${name}-${m.name}";
        }) (tunnel.mounts or [])
    )
    clientTunnels);
  mountRowJson = p:
    pkgs.writeText "vps-mount-${p.agent}.json" (builtins.toJSON {
      host = p.name;
      inherit (p) mountpoint;
      address = p.hostName;
      inherit (p) user;
      mount = p.m;
      authSock = identityAgent;
    });

  # Per-row identity bundle rows on the shared owner: Login Items & Extensions resolves the agent's AssociatedBundleIdentifiers to
  # "<Name> VPS Tunnel" instead of the "/bin/sh" basename.
  tunnelTitle = name: "${lib.toSentenceCase name} VPS Tunnel";
  tunnelBundleId = name: "com.parametric-forge.${name}-vps-tunnel";
  receiptsFold = import ./receipts.nix;

  # Health-gated supervisor: spawns ssh -N, proves every local bind, then emits service-health receipts on state transitions. Restart-worthy
  # states are transport-scoped only (port-conflict, vps-unreachable, bind-failed, bind-lost) — service-down is receipted, never restarted: a
  # local restart cannot fix a remote service, and churn would mask real VPS outages.
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

      # Knobs are positive integers or the defaults — a stray override must never crash the supervisor into a receiptless restart loop.
      case "$interval" in "" | *[!0-9]* | 0) interval=60 ;; esac
      case "$bind_grace" in "" | *[!0-9]* | 0) bind_grace=20 ;; esac
      case "$bind_fail_max" in "" | *[!0-9]* | 0) bind_fail_max=3 ;; esac

      mapfile -t ports < <(jq -r '.forwards[].port' "$row_file")

      # Dual receipt through the shared fold: TSV stays the human/log contract, the JSONL sibling carries identical keys including the services vector.
      receipt_log="$receipts"
      receipt_surface="vps-tunnel"
      ${receiptsFold}
      emit() {
        local ts row
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        printf -v row 'ts=%s\ttunnel=%s\tstate=%s\t%s' "$ts" "$name" "$1" "''${2:-}"
        append_receipt "$row" || true
        printf '%s\n' "$row"
      }

      port_open() { (exec {tcp_fd}<>"/dev/tcp/127.0.0.1/$1" && exec {tcp_fd}>&-) 2>/dev/null; }

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

      # Loopback parity guard: a port accepting before ssh spawns belongs to another owner (compose local mode) — receipt the truth, never let
      # the collision masquerade as vps-unreachable or bind-failed.
      conflicts=""
      for p in "''${ports[@]}"; do port_open "$p" && conflicts="$conflicts $p"; done
      if [ -n "$conflicts" ]; then
        # Holder identification at the receipt separates routine (colima local parity mode) from regression (a shared ssh mux retaining forwards).
        read -ra cports <<<"$conflicts"
        # lsof exits 1 when a holder vanished between probes; under pipefail that rc would kill the run before the receipt lands.
        holders="$(for p in "''${cports[@]}"; do
          lsof -nP -iTCP:"$p" -sTCP:LISTEN 2>/dev/null | awk -v port="$p" 'NR>1 {print port":"$1":"$2}' || true
        done | sort -u | paste -sd, -)"
        emit port-conflict "detail=already bound before spawn:$conflicts holders=''${holders:-unknown}"
        exit 1
      fi

      # Traps precede the spawn: TERM in the spawn window must still reap ssh, and untrapped SIGTERM would skip the EXIT trap on launchd unload.
      ssh_pid=""
      trap '{ [ -n "$ssh_pid" ] && kill "$ssh_pid" 2>/dev/null && wait "$ssh_pid" 2>/dev/null; } || true' EXIT
      trap 'exit 143' TERM INT
      ssh -N "$ssh_host" &
      ssh_pid=$!

      # Bind proof: ssh death before binds is vps-unreachable; a live ssh whose forwards never accept within the grace window is bind-failed.
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

  # Mount supervisor: one rclone per (host, mount) row — nfsmount on Darwin (userspace NFS + native mount, no kext, no sudo), FUSE on Linux. The
  # remote is a config-free connection string; identity is the 1Password agent socket. rclone survives a backend drop (lazy reconnect) while the
  # OS ejects the volume, so readiness is proven continuously: a health loop probes process, device, and statfs; a failed verdict drains, receipts, and exits;
  # KeepAlive relaunches. Drain order is the clean-eject law: detach while the NFS server answers, THEN reap rclone; reverse is the interrupted-server dialog.
  mountSupervisor = pkgs.writeShellApplication {
    name = "forge-vps-mount";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.rclone pkgs.openssh] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [pkgs.util-linux pkgs.procps];
    text = ''
      row_file="$1"
      IFS=$'\x1f' read -r hostname mname rpath ro cache addr user mountpoint auth_sock < <(jq -r \
        '[.host, .mount.name, .mount.path, (.mount.readOnly | tostring), .mount.cache,
          .address, .user, .mountpoint, .authSock] | join("\u001f")' "$row_file")
      grace="''${FORGE_MOUNT_GRACE:-30}"
      probe_interval="''${FORGE_MOUNT_PROBE_INTERVAL:-30}"
      probe_fail_max="''${FORGE_MOUNT_PROBE_FAILS:-3}"
      case "$grace" in "" | *[!0-9]* | 0) grace=30 ;; esac
      case "$probe_interval" in "" | *[!0-9]* | 0) probe_interval=30 ;; esac
      case "$probe_fail_max" in "" | *[!0-9]* | 0) probe_fail_max=3 ;; esac
      receipt_log="''${FORGE_MOUNT_RECEIPTS:-$HOME/Library/Logs/forge-$hostname-mount-$mname.receipts.log}"
      receipt_surface="vps-mount"
      volname="forge-$hostname-$mname"
      ${receiptsFold}
      emit() {
        local ts row
        TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
        printf -v row 'ts=%s\tmount=%s-%s\tstate=%s\t%s' "$ts" "$hostname" "$mname" "$1" "''${2:-}"
        append_receipt "$row" || true
        printf '%s\n' "$row"
      }

      # Mountpoint truth is the device number: a mounted dir sits on a different device than its parent — no mount-table parsing, both OS.
      mounted() {
        [ "$(stat -c %d "$mountpoint" 2>/dev/null || echo x)" != "$(stat -c %d "''${mountpoint%/*}" 2>/dev/null || echo y)" ]
      }

      # Volume detach while the NFS server still answers: plain umount asks the OS for a clean eject, the fallback forces a busy volume. The
      # verdict (absent|clean|forced|lazy|failed) is receipt data.
      detach() {
        mounted || { printf 'absent'; return 0; }
        case "$(uname -s)" in
          Darwin)
            if /sbin/umount "$mountpoint" 2>/dev/null; then printf 'clean'; return 0; fi
            if /usr/sbin/diskutil unmount force "$mountpoint" >/dev/null 2>&1; then printf 'forced'; return 0; fi
            ;;
          *)
            if umount "$mountpoint" 2>/dev/null; then printf 'clean'; return 0; fi
            if umount -l "$mountpoint" 2>/dev/null; then printf 'lazy'; return 0; fi
            ;;
        esac
        printf 'failed'
      }

      reap() { # bounded TERM -> KILL over pids; rclone exits fast once detached
        local pid live
        [ "$#" -gt 0 ] || return 0
        kill "$@" 2>/dev/null || true
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          live=0
          for pid in "$@"; do kill -0 "$pid" 2>/dev/null && live=1; done
          [ "$live" = 1 ] || return 0
          sleep 0.5
        done
        kill -9 "$@" 2>/dev/null || true
      }

      # Stale-owner recovery: a prior rclone outlives both its supervisor and the volume (an external eject never stops the NFS server). Reap by
      # volname before this instance serves the same mountpoint twice.
      case "$(uname -s)" in Darwin) pgrep_bin=/usr/bin/pgrep ;; *) pgrep_bin=pgrep ;; esac
      mapfile -t stale < <("$pgrep_bin" -U "$(id -u)" -f -- "rclone (nfsmount|mount) .*--volname $volname( |$)" 2>/dev/null || true)
      if [ "''${#stale[@]}" -gt 0 ]; then
        reap "''${stale[@]}"
        emit reaped "detail=stale rclone pids=''${stale[*]}"
      fi

      mkdir -p "$mountpoint"
      export SSH_AUTH_SOCK="$auth_sock"

      # Stale-mount reclaim: anything still on the mountpoint after the reap belongs to another owner — receipt the conflict, never mount over it.
      stale_detach="$(detach)"
      if mounted; then
        emit mount-conflict "detail=$mountpoint held by another owner (detach=$stale_detach)"
        exit 1
      fi

      # External openssh transport: rclone's internal ssh library sends no keepalives, so NAT/idle drops silently kill the warm session and the
      # next statfs rides a doomed handshake — macOS answers with the interrupted-server dialog. ServerAlive keepalives (the tunnel posture) hold
      # the standing connection; auth/known-hosts ride openssh + agent.
      remote=":sftp,ssh='ssh -o BatchMode=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -l $user $addr',idle_timeout=0:$rpath"
      sub=nfsmount
      [ "$(uname -s)" = "Darwin" ] || sub=mount
      flags=(--config "" --volname "$volname" --vfs-cache-mode "$cache")
      [ "$ro" != "true" ] || flags+=(--read-only)

      # Traps precede the spawn; drain emits `down` only after a landed mount (pre-mount failures carry their own states). ExitTimeOut (45s) on
      # the agent row outlives the worst-case detach + reap.
      rclone_pid=""
      mounted_once=""
      drained=""
      drain() { # $1 = cause — detach first, reap second, receipt the truth
        [ -z "$drained" ] || return 0
        drained="$1"
        local how
        how="$(detach)"
        [ -z "$rclone_pid" ] || reap "$rclone_pid"
        rclone_pid=""
        [ -z "$mounted_once" ] || emit down "detail=cause=$1 detach=$how"
      }
      trap 'drain exit' EXIT
      trap 'drain term; trap - EXIT; exit 143' TERM INT
      rclone "$sub" "$remote" "$mountpoint" "''${flags[@]}" &
      rclone_pid=$!

      deadline=$((SECONDS + grace))
      until mounted; do
        if ! kill -0 "$rclone_pid" 2>/dev/null; then
          emit vps-unreachable "detail=rclone exited before the mount landed"
          exit 1
        fi
        if [ "$SECONDS" -ge "$deadline" ]; then
          emit mount-failed "detail=no mount within ''${grace}s"
          exit 1
        fi
        sleep 1
      done
      mounted_once=1
      emit mounted "detail=$mountpoint ro=$ro cache=$cache"

      # Health loop: process, device, then statfs through the mount reaching the SFTP backend via the NFS server, and timeout bounds an NFS stall.
      # Consecutive failures get tunnel-style hysteresis; eject and exit drain immediately, and every exit relaunches under KeepAlive/Restart=always.
      probe_fails=0
      while :; do
        # Backgrounded sleep keeps the interval interruptible by TERM/INT.
        sleep "$probe_interval" &
        wait "$!" || true
        if ! kill -0 "$rclone_pid" 2>/dev/null; then
          rc=0
          wait "$rclone_pid" || rc=$?
          rclone_pid=""
          drain "rclone-exited rc=$rc"
          exit 1
        fi
        if ! mounted; then
          drain ejected
          exit 1
        fi
        if timeout 10 stat -f -c %b "$mountpoint" >/dev/null 2>&1; then
          probe_fails=0
        else
          probe_fails=$((probe_fails + 1))
          if [ "$probe_fails" -ge "$probe_fail_max" ]; then
            drain "backend-lost after $probe_fails probes"
            exit 1
          fi
        fi
      done
    '';
  };
in {
  # Host rows projected for downstream consumers (WezTerm ssh_domains, Yazi VFS, workspace picker, receipt registry): transport facts, forwards
  # reduced to service/port pairs, and mount rows carrying their mountpoints.
  options.forge.ssh = {
    hosts = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      default =
        lib.mapAttrs (name: tunnel: {
          inherit name;
          inherit (tunnel) user hostName;
          aliases = ["${name}-vps" name];
          tunnelHost = "${name}-tunnel";
          forwards = map (f: {inherit (f) port service;}) tunnel.forwards;
          mounts = map (m: m // {mountpoint = "${mountRoot}/${name}-${m.name}";}) (tunnel.mounts or []);
        })
        vpsTunnels;
      description = "SSH estate host rows: interactive aliases, transport identity, declared forwards, mount rows.";
    };
    identityAgent = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = identityAgent;
      description = "1Password agent socket every remote surface pins (ssh, WezTerm mux, Yazi VFS, rclone).";
    };
    mountRoot = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = mountRoot;
      description = "Root directory holding the rclone VPS mountpoints.";
    };
  };

  config =
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false; # suppress the default-config deprecation warning

        settings =
          {
            # --- [GITHUB_CONFIGURATION]
            "github.com" = {
              User = "git";
              HostName = "github.com";
              IdentitiesOnly = true;
              AddKeysToAgent = "yes";
            };

            # --- [DEFAULT_OPTIMIZATIONS_FOR_ALL_HOSTS]
            "*" =
              lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
                # 1Password's stable agent socket is the identity source on Darwin; Linux hosts authenticate inbound through authorized keys.
                IdentityAgent = "\"${identityAgent}\"";
              }
              // {
                ControlMaster = "auto";
                ControlPath = "${config.home.homeDirectory}/.ssh/sockets/%C";
                ControlPersist = "10m";

                ServerAliveInterval = 60;
                ServerAliveCountMax = 3;

                AddKeysToAgent = "yes";
                HashKnownHosts = true;

                Compression = true;
              };
          }
          // interactiveHosts
          // tunnelHosts;
      };

      forge.bundleApps =
        lib.mapAttrs' (name: _: lib.nameValuePair "${name}-vps-tunnel" (tunnelTitle name)) vpsTunnels
        // lib.listToAttrs (map (p: lib.nameValuePair p.agent "${lib.toSentenceCase p.name} Mount ${lib.toSentenceCase p.m.name}") mountPairs);

      # Durable per-row tunnel + mount agents; local parity mode boots the tunnels out before compose binds the same loopback ports.
      # KeepAlive=true implies RunAtLoad, so the pair never coexists. ExitTimeOut on mounts outlives the rclone unmount drain — the launchd 20s
      # default SIGKILLs the teardown and strands a dead NFS mountpoint.
      launchd.agents =
        lib.mapAttrs' (name: tunnel:
          lib.nameValuePair "${name}-vps-tunnel" {
            enable = true;
            config = {
              Label = "com.parametric-forge.${name}-vps-tunnel";
              ProgramArguments = ["${tunnelSupervisor}/bin/forge-vps-tunnel" "${tunnelRowJson name tunnel}"];
              KeepAlive = true;
              ThrottleInterval = 30;
              ProcessType = "Background";
              StandardOutPath = "${homeDir}/Library/Logs/forge-${name}-vps-tunnel.log";
              StandardErrorPath = "${homeDir}/Library/Logs/forge-${name}-vps-tunnel.log";
              AssociatedBundleIdentifiers = [(tunnelBundleId name)];
            };
          })
        clientTunnels
        // lib.listToAttrs (map (p:
          lib.nameValuePair p.agent {
            enable = true;
            config = {
              Label = "com.parametric-forge.${p.agent}";
              ProgramArguments = ["${mountSupervisor}/bin/forge-vps-mount" "${mountRowJson p}"];
              KeepAlive = true;
              ThrottleInterval = 30;
              ExitTimeOut = 45;
              ProcessType = "Background";
              StandardOutPath = "${homeDir}/Library/Logs/forge-${p.agent}.log";
              StandardErrorPath = "${homeDir}/Library/Logs/forge-${p.agent}.log";
              AssociatedBundleIdentifiers = ["com.parametric-forge.${p.agent}"];
            };
          })
        mountPairs);
    }
    # Static host gate: config attr names must never depend on pkgs (fixpoint).
    // lib.optionalAttrs (host.os == "nixos") {
      systemd.user.services =
        lib.mapAttrs' (name: tunnel:
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
        clientTunnels
        // lib.listToAttrs (map (p:
          lib.nameValuePair p.agent {
            Unit.Description = "Forge VPS mount ${p.agent}";
            Service = {
              ExecStart = "${mountSupervisor}/bin/forge-vps-mount ${mountRowJson p}";
              Environment = ["FORGE_MOUNT_RECEIPTS=%h/.local/state/forge-mounts/${p.agent}.receipts.log"];
              Restart = "always";
              RestartSec = 30;
              TimeoutStopSec = 45;
            };
            Install.WantedBy = ["default.target"];
          })
        mountPairs);
    };
}
