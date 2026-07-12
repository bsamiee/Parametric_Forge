# Title         : supervise-stdio.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/supervise-stdio.nix
# ----------------------------------------------------------------------------
# Supervised stdio lane shared by every MCP launcher: blocking byte relays bind both protocol directions to a bounded activity lease, while EOF,
# server exit, wrapper death, and termination signals converge on one whole-process-group reap. A lifeline guardian survives wrapper SIGKILL,
# retained client pipe writers cannot hold an abandoned generation forever, and inherited server stderr stays outside the JSON-RPC stream.
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
  work="$(mktemp -d "''${TMPDIR:-/tmp}/forge-stdio.XXXXXX")"
  activity="$work/activity"
  printf '%s\n' "$BASH_MONOSECONDS" >"$activity"

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
    local last="$BASH_MONOSECONDS" now read_status
    trap 'exit 0' TERM INT HUP
    while :; do
      read_status=0
      IFS= read -r -t 1 _ || read_status=$?
      if ((read_status == 1)); then
        break
      fi
      if ((read_status > 128)); then
        now="$BASH_MONOSECONDS"
        if [[ -s "$activity_file" ]]; then
          IFS= read -r last <"$activity_file" || true
        fi
        [[ "$last" =~ ^[0-9]+$ ]] || last="$now"
        ((now >= last && now - last >= idle_seconds)) && break
        continue
      fi
      break
    done
    trap - TERM INT HUP
    stop_tree "$server_pid" "$in_pid" "$out_pid"
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
    exit "$rc"
  fi

  # A relay ended before the server: preserve a prompt EOF-driven server exit, then classify forced lifecycle retirement as successful supervision.
  sleep 1
  if kill -0 "$srv" 2>/dev/null; then
    exit 0
  fi
  wait "$srv" 2>/dev/null || rc=$?
  exit "$rc"
''
