#!/usr/bin/env bash
# External-worker emit helper: the opt-in richer lane for codex/agy (and any wrapped external model) to declare itself into the delegation ledger the
# fleet roster folds. One call opens a lane (--state running), a later call closes it (--state done|failed|cancelled), paired by --wid. When wrappers do
# not call this, forge-fleet-status still surfaces the process via its scan; this helper adds the resolved model, label, and exit truth a scan cannot
# see. Rows stamp the caller's inherited CLAUDE_CODE_SESSION_ID (override: FORGE_FLEET_SESSION) so the roster scopes lanes to their owning session even
# after the worker pid dies or daemonizes away from its ancestry.
set -Eeuo pipefail
shopt -s inherit_errexit
[ -n "${FORGE_FLEET_DEBUG:-}" ] || trap 'exit 0' ERR

ledger="${FORGE_FLEET_LEDGER:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/delegation.jsonl}"
session="${FORGE_FLEET_SESSION:-${CLAUDE_CODE_SESSION_ID:-}}"
kind="external" label="" model="" effort="" state="running" wid="" pid="${FORGE_FLEET_PID:-}"

while [ $# -gt 0 ]; do
    case "$1" in
        --kind)
            kind="$2"
            shift 2
            ;;
        --label)
            label="$2"
            shift 2
            ;;
        --model)
            model="$2"
            shift 2
            ;;
        --effort)
            effort="$2"
            shift 2
            ;;
        --state)
            # Normalize wrapper spellings to the fold vocabulary: start->running, stop->done.
            case "$2" in start) state="running" ;; stop) state="done" ;; *) state="$2" ;; esac
            shift 2
            ;;
        --wid)
            wid="$2"
            shift 2
            ;;
        --pid)
            pid="$2"
            shift 2
            ;;
        --session)
            session="$2"
            shift 2
            ;;
        *) shift ;;
    esac
done
[ -n "$wid" ] || wid="${kind}-$$"

mkdir -p "${ledger%/*}"
jq -nc --argjson t "$EPOCHSECONDS" \
    --arg wid "$wid" --arg kind "$kind" --arg label "$label" --arg model "$model" --arg effort "$effort" --arg state "$state" --arg pid "$pid" \
    --arg session "$session" \
    '{t: $t, ev: "worker", wid: $wid, kind: $kind, label: ($label | if . == "" then null else .[0:48] end),
      model: ($model | if . == "" then null else . end), effort: ($effort | if . == "" then null else . end), state: $state,
      pid: (if $pid == "" then null else ($pid | tonumber?) end), session_id: (if $session == "" then null else $session end)}' >>"$ledger" 2>/dev/null
