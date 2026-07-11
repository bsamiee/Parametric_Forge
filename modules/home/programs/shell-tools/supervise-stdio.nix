# Title         : supervise-stdio.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/shell-tools/supervise-stdio.nix
# ----------------------------------------------------------------------------
# Supervised stdio lane shared by every MCP launcher: client stdin reaches the server through a relay `cat`, so ANY client departure — clean exit,
# SIGKILL, or an in-place reconnect that closes the old pipes — ends the relay, and the wrapper then reaps the server's whole process group. This is
# the only structural guarantee against residue: fleet servers demonstrably ignore stdin EOF and outlive closed pipes, and a ppid watchdog misses the
# live-client-reconnect case entirely. Server stdout/stderr stay inherited, so the JSON-RPC return path and logging are untouched.
server: ''
  exec {relay_fd}< <(exec cat)
  relay=$!
  set -m
  ${server} "$@" <&"$relay_fd" &
  srv=$!
  set +m
  exec {relay_fd}<&-
  reap() {
    kill -TERM -- "-$srv" 2>/dev/null || kill -TERM "$srv" 2>/dev/null || true
  }
  trap reap TERM INT HUP
  rc=0
  wait -n "$relay" "$srv" 2>/dev/null || rc=$?
  if kill -0 "$srv" 2>/dev/null; then
    # Relay ended first: the client is gone. Grace for the server's own EOF exit, then TERM the group, KILL residue.
    for _ in 1 2 3 4 5; do
      kill -0 "$srv" 2>/dev/null || break
      sleep 1
    done
    reap
    sleep 2
    kill -KILL -- "-$srv" 2>/dev/null || true
    if wait "$srv" 2>/dev/null; then
      rc=0
    else
      w=$?
      [ "$w" -eq 127 ] || rc=$w
    fi
  else
    # Server ended first: surface its exit status (127 means wait -n already reaped it and rc holds the truth) and release the relay.
    if wait "$srv" 2>/dev/null; then
      rc=0
    else
      w=$?
      [ "$w" -eq 127 ] || rc=$w
    fi
    kill "$relay" 2>/dev/null || true
  fi
  exit "$rc"
''
