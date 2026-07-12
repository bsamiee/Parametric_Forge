# Title         : supervise-stdio.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/supervise-stdio.nix
# ----------------------------------------------------------------------------
# Supervised stdio lane shared by every MCP launcher: byte-preserving relays bind both protocol directions to a bounded activity lease, while EOF,
# server exit, wrapper exit, and termination signals converge on one whole-process-group reap. Retained client pipe writers cannot hold an abandoned
# generation forever, and inherited server stderr preserves the diagnostic lane without entering the JSON-RPC stream.
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

  # Reached through cleanup invoked by trap; ShellCheck cannot trace trap-invoked calls.
  # shellcheck disable=SC2329
  server_alive() {
    ((srv > 0)) || return 1
    kill -0 -- "-$srv" 2>/dev/null || kill -0 "$srv" 2>/dev/null
  }

  # Reached through cleanup invoked by trap; ShellCheck cannot trace trap-invoked calls.
  # shellcheck disable=SC2329
  signal_server() {
    local signal="$1"
    ((srv > 0)) || return 0
    kill -"$signal" -- "-$srv" 2>/dev/null || kill -"$signal" "$srv" 2>/dev/null || true
  }

  # shellcheck disable=SC2329
  cleanup() {
    local status=$?
    local child
    local drain_timer=0
    local drained=
    trap - EXIT TERM INT HUP ALRM
    for child in "$input_relay" "$watchdog"; do
      ((child > 0)) && kill -TERM "$child" 2>/dev/null || true
    done
    signal_server TERM
    for _ in 1 2; do
      server_alive || break
      sleep 1
    done
    signal_server KILL
    ((srv > 0)) && wait "$srv" 2>/dev/null || true
    if ((output_relay > 0)) && kill -0 "$output_relay" 2>/dev/null; then
      sleep 2 &
      drain_timer=$!
      wait -n -p drained "$output_relay" "$drain_timer" 2>/dev/null || true
      [[ "$drained" == "$output_relay" ]] || kill -TERM "$output_relay" 2>/dev/null || true
      kill -TERM "$drain_timer" 2>/dev/null || true
      wait "$drain_timer" 2>/dev/null || true
    fi
    for child in "$input_relay" "$output_relay" "$watchdog"; do
      ((child > 0)) && wait "$child" 2>/dev/null || true
    done
    exit "$status"
  }

  watchdog_loop() {
    local parent="$1"
    local read_status=0
    while IFS= read -r -t "$idle_seconds" _; do
      :
    done
    read_status=$?
    if ((read_status > 128)); then
      kill -ALRM "$parent" 2>/dev/null || true
    fi
  }

  relay_stream() {
    local chunk
    local read_status
    while :; do
      chunk=
      read_status=0
      IFS= read -r -d "" -n 4096 -t 0.1 chunk || read_status=$?
      if [[ -n "$chunk" ]]; then
        printf '%s' "$chunk"
        printf '.\n' 1>&"$activity_fd" 2>/dev/null || true
      fi
      ((read_status == 0 || read_status > 128)) && continue
      return 0
    done
  }

  trap cleanup EXIT
  trap 'exit 143' TERM
  trap 'exit 130' INT
  trap 'exit 129' HUP
  trap 'exit 0' ALRM

  exec {activity_fd}> >(watchdog_loop "$$")
  watchdog=$!

  exec {server_stdin}< <(relay_stream)
  input_relay=$!
  exec {server_stdout}> >(relay_stream)
  output_relay=$!
  exec {activity_fd}>&-
  set -m
  ${server} "$@" <&"$server_stdin" >&"$server_stdout" &
  srv=$!
  set +m
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
