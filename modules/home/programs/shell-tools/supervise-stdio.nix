# Title         : supervise-stdio.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/supervise-stdio.nix
# ----------------------------------------------------------------------------
# Supervised stdio lane shared by every MCP launcher: EOF, server exit, wrapper death, and termination signals converge on one
# whole-process-group reap, and a lifeline guardian survives wrapper SIGKILL. The idle lease governs only abandoned generations — a dead or
# unprobeable client expires under it, while a live client renews it indefinitely, so an idle session never sees its server disconnect.
# Client liveness pins launch-time process identity (lstart), so a recycled PID never renews a dead client's lease. Every reap appends one
# schema=forge-mcp/v1 TSV exit receipt (server, pid, cause, code, uptime, client state) to the forge-mcp receipt log — file-only, never stdout.
# Inherited server stderr stays outside the JSON-RPC stream.
server: ''
  idle_seconds="''${FORGE_STDIO_IDLE_SECONDS:-900}"
  if [[ ! "$idle_seconds" =~ ^[1-9][0-9]*$ ]]; then
    printf 'FORGE_STDIO_IDLE_SECONDS must be a positive integer, got: %s\n' "$idle_seconds" >&2
    exit 64
  fi

  input_relay=0
  output_relay=0
  watchdog=0
  srv=0
  life_fd=0
  client_pid="$PPID"
  client_lstart="$(ps -o lstart= -p "$client_pid" 2>/dev/null || true)"
  server_name="$(basename ${server})"
  srv_started="$BASH_MONOSECONDS"
  receipt_log="''${FORGE_MCP_RECEIPT_LOG:-$HOME/Library/Logs/forge-mcp.receipts.log}"
  work="$(mktemp -d "''${TMPDIR:-/tmp}/forge-stdio.XXXXXX")"
  activity="$work/activity"
  printf '%s\n' "$BASH_MONOSECONDS" >"$activity"

  client_alive() {
    ((client_pid > 1)) || return 1
    kill -0 "$client_pid" 2>/dev/null || return 1
    [[ -z "$client_lstart" ]] || [[ "$(ps -o lstart= -p "$client_pid" 2>/dev/null)" == "$client_lstart" ]]
  }

  receipt() {
    local -r cause="$1" code="$2"
    local alive=dead
    client_alive && alive=live
    mkdir -p "$(dirname "$receipt_log")" 2>/dev/null || return 0
    printf 'schema=forge-mcp/v1\tkind=stdio-reap\tts=%s\tserver=%s\tpid=%s\tcause=%s\tcode=%s\tuptime_s=%s\tclient=%s\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$server_name" "$srv" "$cause" "$code" \
      "$((BASH_MONOSECONDS - srv_started))" "$alive" >>"$receipt_log" 2>/dev/null || true
  }

  sweep_stale_generations() {
    # A hard SIGKILL or orphan-then-kill bypasses both the cleanup EXIT trap and the guardian rm, stranding that generation's work dir;
    # SIGKILL is untrappable, so the leak reaps at the next launch, not at exit. A live generation renews its activity file within
    # idle_seconds, so reaping only siblings whose activity aged past 2*idle_seconds — or that never wrote one — clears the dead
    # without racing a quiet-but-live session or a sibling mktemp still in flight.
    local -r stale_min=$(( (idle_seconds * 2 + 59) / 60 ))
    local act dir
    while IFS= read -r act; do
      dir="''${act%/activity}"
      [[ "$dir" == "$work" ]] && continue
      rm -rf -- "$dir" 2>/dev/null || true
    done < <(find "''${TMPDIR:-/tmp}" -maxdepth 2 -type f -name activity -path '*/forge-stdio.*/activity' -mmin +"$stale_min" 2>/dev/null)
    find "''${TMPDIR:-/tmp}" -maxdepth 1 -type d -name 'forge-stdio.*' -empty -mmin +"$stale_min" ! -path "$work" -exec rm -rf -- {} + 2>/dev/null || true
  }

  tree_alive() {
    local -r server_pid="$1"
    ((server_pid > 0)) || return 1
    kill -0 -- "-$server_pid" 2>/dev/null || kill -0 "$server_pid" 2>/dev/null
  }

  signal_tree() {
    local -r signal="$1" server_pid="$2"
    ((server_pid > 0)) || return 0
    kill -"$signal" -- "-$server_pid" 2>/dev/null || kill -"$signal" "$server_pid" 2>/dev/null || true
  }

  stop_tree() {
    local -r server_pid="$1" in_pid="$2" out_pid="$3"
    local child drain_timer=0 drained=
    ((in_pid > 0)) && kill -TERM "$in_pid" 2>/dev/null || true
    signal_tree TERM "$server_pid"
    for _ in 1 2; do
      tree_alive "$server_pid" || break
      sleep 1
    done
    signal_tree KILL "$server_pid"
    if ((out_pid > 0)) && kill -0 "$out_pid" 2>/dev/null; then
      sleep 2 &
      drain_timer=$!
      wait -n -p drained "$out_pid" "$drain_timer" 2>/dev/null || true
      [[ "$drained" == "$out_pid" ]] || kill -TERM "$out_pid" 2>/dev/null || true
      kill -TERM "$drain_timer" 2>/dev/null || true
      wait "$drain_timer" 2>/dev/null || true
    fi
    for child in "$in_pid" "$out_pid"; do
      ((child > 0)) && kill -KILL "$child" 2>/dev/null || true
    done
  }

  # shellcheck disable=SC2329
  cleanup() {
    local status=$?
    local child
    trap - EXIT TERM INT HUP
    ((watchdog > 0)) && kill -TERM "$watchdog" 2>/dev/null || true
    ((watchdog > 0)) && wait "$watchdog" 2>/dev/null || true
    ((life_fd > 0)) && exec {life_fd}>&- || true
    stop_tree "$srv" "$input_relay" "$output_relay"
    ((srv > 0)) && wait "$srv" 2>/dev/null || true
    for child in "$input_relay" "$output_relay"; do
      ((child > 0)) && wait "$child" 2>/dev/null || true
    done
    rm -rf -- "$work"
    exit "$status"
  }

  guardian_loop() {
    local -r server_pid="$1" in_pid="$2" out_pid="$3" activity_file="$4" work_dir="$5"
    local last="$BASH_MONOSECONDS" now read_status cause="lifeline-eof"
    trap 'exit 0' TERM INT HUP
    while :; do
      read_status=0
      IFS= read -r -t 1 _ || read_status=$?
      if ((read_status == 1)); then
        break
      fi
      if ((read_status > 128)); then
        # Parent-liveness gate: a hard client SIGKILL orphans the wrapper with relays blocked on reads that never see EOF, so the
        # lifeline never closes; probing the launching client (identity-pinned) reaps the generation within a poll instead of waiting
        # out the idle lease.
        if ((client_pid > 1)) && ! client_alive; then
          cause="client-death"
          break
        fi
        now="$BASH_MONOSECONDS"
        if [[ -s "$activity_file" ]]; then
          IFS= read -r last <"$activity_file" || true
        fi
        [[ "$last" =~ ^[0-9]+$ ]] || last="$now"
        if ((now >= last && now - last >= idle_seconds)); then
          # Live-client hold: a provably live, identity-matched client renews the lease, so a quiet session never loses its server
          # mid-run; expiry reaps only generations without a probeable same-identity client, whose relays may hold no EOF to converge on.
          if ! client_alive; then
            cause="idle-expiry"
            break
          fi
          printf '%s\n' "$now" >"$activity_file"
        fi
        continue
      fi
      cause="lifeline-close"
      break
    done
    trap - TERM INT HUP
    stop_tree "$server_pid" "$in_pid" "$out_pid"
    receipt "$cause" "-"
    rm -rf -- "$work_dir"
  }

  relay_stream() {
    local chunk rest
    while LC_ALL=C IFS= read -r -N 1 chunk; do
      rest=
      LC_ALL=C IFS= read -r -N 65535 -t 0.001 rest || true
      chunk+="$rest"
      printf '%s' "$chunk"
      printf '%s\n' "$BASH_MONOSECONDS" >"$activity"
    done
  }

  trap cleanup EXIT
  trap 'exit 143' TERM
  trap 'exit 130' INT
  trap 'exit 129' HUP

  sweep_stale_generations

  exec {server_stdin}< <(relay_stream)
  input_relay=$!
  exec {server_stdout}> >(relay_stream)
  output_relay=$!
  set -m
  ${server} "$@" <&"$server_stdin" >&"$server_stdout" &
  srv=$!
  set +m
  exec {life_fd}> >(guardian_loop "$srv" "$input_relay" "$output_relay" "$activity" "$work")
  watchdog=$!
  exec {server_stdin}<&-
  exec {server_stdout}>&-

  finished=
  rc=0
  wait -fn -p finished "$input_relay" "$output_relay" "$watchdog" "$srv" 2>/dev/null || rc=$?
  if [[ "$finished" == "$srv" ]]; then
    receipt "server-exit" "$rc"
    exit "$rc"
  fi

  # A relay ended before the server: preserve a prompt EOF-driven server exit, then classify forced lifecycle retirement as successful supervision.
  sleep 1
  if kill -0 "$srv" 2>/dev/null; then
    receipt "client-disconnect" "-"
    exit 0
  fi
  wait "$srv" 2>/dev/null || rc=$?
  receipt "client-disconnect" "$rc"
  exit "$rc"
''
