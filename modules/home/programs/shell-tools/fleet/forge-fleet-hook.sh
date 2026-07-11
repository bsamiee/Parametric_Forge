#!/usr/bin/env bash
# Delegation ledger writer for the fleet roster: one JSONL row per subagent/task lifecycle event on Claude Code hook stdin, folded live by
# forge-fleet-status. Handles SubagentStart|SubagentStop|TaskCompleted (worker rows) and Stop|SubagentStop (a background_tasks snapshot row that
# carries the native typed in-flight picture). Every row is stamped with the payload's session_id so the roster scopes to its owning session.
# Append-only; any failure exits 0 so a hook never blocks the harness. Size-gated self-rotation behind a stale-tolerant mkdir lock.
set -Eeuo pipefail
[ -n "${FORGE_FLEET_DEBUG:-}" ] || trap 'exit 0' ERR

# Whole-body deadline: re-exec under timeout so no stage can strand a hook body. bash-5.3 backs sub-64K here-docs/here-strings with a pipe the
# redirecting process holds both ends of; under kernel pipe-buffer exhaustion that write deadlocks pre-exec, so the payload rides a temp FILE
# into every jq below and the deadline forecloses any residual wedge.
if [ -z "${_FORGE_HOOK_DEADLINE:-}" ] && command -v timeout >/dev/null 2>&1; then
    _FORGE_HOOK_DEADLINE=1 exec timeout -k 5 45 "$0" "$@"
fi

ledger="${FORGE_FLEET_LEDGER:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/delegation.jsonl}"
max_rows="${FORGE_FLEET_MAX_ROWS:-4000}"
keep_rows="${FORGE_FLEET_KEEP_ROWS:-1000}"
mkdir -p "${ledger%/*}"

# Bounded stdin read: the read builtin consumes to EOF (or the 20s guard when a harness holds the pipe open) with no cat fork and no
# command-substitution pipe; a timeout keeps whatever partial payload arrived.
payload=""
IFS= read -r -t 20 -d '' payload || true
[ -n "$payload" ] || exit 0
pf="$(mktemp "${TMPDIR:-/tmp}/forge-fleet.XXXXXX")"
trap 'rm -f "$pf"' EXIT
printf '%s' "$payload" >"$pf"
event="$(jq -r '.hook_event_name // "unknown"' "$pf")"

emit() { printf '%s\n' "$1" >>"$ledger" 2>/dev/null; }

# Worker row: state=running opens a lane, state=done|failed closes it; wid pairs the two. label is the agent/task name the roster renders.
worker_row() {
    jq -c --argjson t "$EPOCHSECONDS" \
        --arg wid "$1" --arg kind "$2" --arg label "$3" --arg model "$4" --arg state "$5" \
        '{t: $t, ev: "worker", wid: $wid, kind: $kind, label: ($label | if . == "" then $kind else .[0:48] end),
          model: ($model | if . == "" then null else . end), state: $state, session_id: (.session_id // "-")}' "$pf"
}

case "$event" in
    SubagentStart)
        emit "$(worker_row "$(jq -r '.agent_id // "-"' "$pf")" subagent "$(jq -r '.agent_type // "agent"' "$pf")" "" "running")"
        ;;
    SubagentStop)
        emit "$(worker_row "$(jq -r '.agent_id // "-"' "$pf")" subagent "$(jq -r '.agent_type // "agent"' "$pf")" "" "done")"
        ;;
    TaskCompleted)
        emit "$(worker_row "$(jq -r '.task_id // "-"' "$pf")" task "$(jq -r '.task_subject // "task"' "$pf")" "" "done")"
        ;;
esac

# Snapshot the native background_tasks array (present on Stop|SubagentStop, v2.1.145+): the typed in-flight roster the renderer reads for the tail count.
case "$event" in
    Stop | SubagentStop)
        emit "$(jq -c --argjson t "$EPOCHSECONDS" \
            '{t: $t, ev: "snapshot", session_id: (.session_id // "-"),
              tasks: ((.background_tasks // []) | map({id, type, status, label: (.name // .agent_type // .description // .type)}))}' "$pf")"
        ;;
esac

# Rotation: one writer wins the mkdir lock and tails the ledger in place; losers skip, and a lock whose holder died is reclaimed after 60s. The tail
# file lives inside the lock dir so a crashed rotation leaves no stray temp, and an append that lands during the tail->mv window is advisory loss.
rows="$(wc -l <"$ledger" 2>/dev/null || echo 0)"
if [ "$rows" -gt "$max_rows" ]; then
    lock="$ledger.lock"
    if mkdir "$lock" 2>/dev/null; then
        printf '%s\n' "$EPOCHSECONDS" >"$lock/t"
        tail -n "$keep_rows" "$ledger" >"$lock/rot" 2>/dev/null && mv -f "$lock/rot" "$ledger"
        rm -rf "$lock"
    else
        held="$(cat "$lock/t" 2>/dev/null || echo 0)"
        if [ $((EPOCHSECONDS - held)) -gt 60 ]; then rm -rf "$lock" 2>/dev/null || true; fi
    fi
fi
