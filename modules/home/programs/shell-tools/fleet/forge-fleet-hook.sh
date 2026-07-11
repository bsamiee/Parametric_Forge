#!/usr/bin/env bash
# Delegation ledger writer for the fleet roster: one JSONL row per subagent/task lifecycle event on Claude Code hook stdin, folded live by
# forge-fleet-status. Handles SubagentStart|SubagentStop|TaskCompleted (worker rows) and Stop|SubagentStop (a background_tasks snapshot row that
# carries the native typed in-flight picture). Every row is stamped with the payload's session_id so the roster scopes to its owning session.
# Append-only; any failure exits 0 so a hook never blocks the harness. Size-gated self-rotation behind a stale-tolerant mkdir lock.
set -Eeuo pipefail
[ -n "${FORGE_FLEET_DEBUG:-}" ] || trap 'exit 0' ERR

ledger="${FORGE_FLEET_LEDGER:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/delegation.jsonl}"
max_rows="${FORGE_FLEET_MAX_ROWS:-4000}"
keep_rows="${FORGE_FLEET_KEEP_ROWS:-1000}"
mkdir -p "${ledger%/*}"

payload="$(cat)"
event="$(jq -r '.hook_event_name // "unknown"' <<<"$payload")"

emit() { printf '%s\n' "$1" >>"$ledger" 2>/dev/null; }

# Worker row: state=running opens a lane, state=done|failed closes it; wid pairs the two. label is the agent/task name the roster renders.
worker_row() {
    jq -c --argjson t "$EPOCHSECONDS" \
        --arg wid "$1" --arg kind "$2" --arg label "$3" --arg model "$4" --arg state "$5" \
        '{t: $t, ev: "worker", wid: $wid, kind: $kind, label: ($label | if . == "" then $kind else .[0:48] end),
          model: ($model | if . == "" then null else . end), state: $state, session_id: (.session_id // "-")}' <<<"$payload"
}

case "$event" in
    SubagentStart)
        emit "$(worker_row "$(jq -r '.agent_id // "-"' <<<"$payload")" subagent "$(jq -r '.agent_type // "agent"' <<<"$payload")" "" "running")"
        ;;
    SubagentStop)
        emit "$(worker_row "$(jq -r '.agent_id // "-"' <<<"$payload")" subagent "$(jq -r '.agent_type // "agent"' <<<"$payload")" "" "done")"
        ;;
    TaskCompleted)
        emit "$(worker_row "$(jq -r '.task_id // "-"' <<<"$payload")" task "$(jq -r '.task_subject // "task"' <<<"$payload")" "" "done")"
        ;;
esac

# Snapshot the native background_tasks array (present on Stop|SubagentStop, v2.1.145+): the typed in-flight roster the renderer reads for the tail count.
case "$event" in
    Stop | SubagentStop)
        emit "$(jq -c --argjson t "$EPOCHSECONDS" \
            '{t: $t, ev: "snapshot", session_id: (.session_id // "-"),
              tasks: ((.background_tasks // []) | map({id, type, status, label: (.name // .agent_type // .description // .type)}))}' <<<"$payload")"
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
