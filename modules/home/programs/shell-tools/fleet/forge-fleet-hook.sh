#!/usr/bin/env bash
# Delegation-ledger observer for Claude lifecycle events. Subagent/task rows and native background-task snapshots share one session-stamped JSONL rail;
# every failure is fail-open, every body is process-group-deadlined, stdin is time/size bounded, and one stale-reclaiming lock serializes hook writers.
set -Eeuo pipefail
shopt -s inherit_errexit

# The raw ~/.claude mirror may inherit no Nix profile paths, so executable binding probes PATH and both user-profile projections explicitly. The
# packaged wrapper remains the deadline owner when timeout itself is dependency-private; a machine missing both rails drops telemetry immediately.
_resolve_executable() {
    local -r name="$1" profile_user="${USER:-${LOGNAME:-}}"
    local candidate=""
    candidate="$(command -v "${name}" 2>/dev/null)" || true
    if [[ -n "${candidate}" && -x "${candidate}" ]]; then
        REPLY="${candidate}"
        return 0
    fi
    if [[ -n "${profile_user}" ]]; then
        candidate="/etc/profiles/per-user/${profile_user}/bin/${name}"
        if [[ -x "${candidate}" ]]; then
            REPLY="${candidate}"
            return 0
        fi
    fi
    candidate="${HOME}/.nix-profile/bin/${name}"
    if [[ -x "${candidate}" ]]; then
        REPLY="${candidate}"
        return 0
    fi
    REPLY=""
    return 1
}

if [[ -z "${_FORGE_FLEET_DEADLINE:-}" ]]; then
    timeout_bin=""
    _resolve_executable timeout && timeout_bin="${REPLY}"
    if [[ -n "${timeout_bin}" ]]; then
        _FORGE_FLEET_DEADLINE=1 "${timeout_bin}" -k 1 4 "${BASH}" "$0" "$@" || true
        exit 0
    fi
    hook_bin=""
    _resolve_executable forge-fleet-hook && hook_bin="${REPLY}"
    if [[ -n "${hook_bin}" ]] && ! [[ "${hook_bin}" -ef "$0" ]]; then
        "${hook_bin}" "$@" || true
    fi
    exit 0
fi

readonly LEDGER="${FORGE_FLEET_LEDGER:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/delegation.jsonl}"
readonly MAX_ROWS_RAW="${FORGE_FLEET_MAX_ROWS:-4000}" KEEP_ROWS_RAW="${FORGE_FLEET_KEEP_ROWS:-1000}"
readonly MAX_PAYLOAD_BYTES=1048576 LOCK="${LEDGER}.lock" REAPER="${LEDGER}.lock.reap" STALE_SECONDS=60
payload_file="" LEDGER_DIR="${LEDGER%/*}" lock_owned=0 reaper_owned=0 REAPER_TOKEN="" MAX_ROWS="" KEEP_ROWS=""
[[ "${LEDGER_DIR}" != "${LEDGER}" ]] || LEDGER_DIR="."
readonly LEDGER_DIR

# shellcheck source=forge-fleet-lock.sh
source "${FORGE_FLEET_LOCK_LIB:-${BASH_SOURCE[0]%/*}/forge-fleet-lock.sh}"

_cleanup() {
    ((reaper_owned)) && _release_reaper || true
    ((lock_owned)) && rm -rf -- "${LOCK}" 2>/dev/null || true
    [[ -z "${payload_file}" ]] || rm -f -- "${payload_file}" 2>/dev/null || true
}
trap '_cleanup' EXIT
trap 'exit 0' TERM INT HUP
[[ -n "${FORGE_FLEET_DEBUG:-}" ]] || trap 'exit 0' ERR

# `read -N` admits at most one MiB plus one sentinel byte; EOF and the one-second guard retain partial input, then jq alone decides whether it is a
# complete event. The foreign payload lands in a private file, so no here-document, here-string, or pre-exec payload pipe exists anywhere downstream.
payload="" read_rc=0
LC_ALL=C IFS= read -r -t 1 -N "$((MAX_PAYLOAD_BYTES + 1))" payload || read_rc=$?
((read_rc != 0)) || exit 0
[[ -n "${payload}" ]] || exit 0
payload_file="$(mktemp "${TMPDIR:-/tmp}/forge-fleet.XXXXXX")"
printf '%s' "${payload}" >"${payload_file}"

_normalize_decimal "${MAX_ROWS_RAW}" 6 MAX_ROWS || exit 0
_normalize_decimal "${KEEP_ROWS_RAW}" 6 KEEP_ROWS || exit 0
((MAX_ROWS > 0 && MAX_ROWS <= 100000 && KEEP_ROWS > 0)) || exit 0
((KEEP_ROWS <= MAX_ROWS)) || exit 0
readonly MAX_ROWS KEEP_ROWS
mkdir -p -- "${LEDGER_DIR}"

_acquire_lock || exit 0

# One jq process owns event admission and row projection; SubagentStop emits both its worker closure and the contemporaneous native-task snapshot.
jq -c --argjson t "${EPOCHSECONDS}" '
  def text($value; $fallback): (($value // $fallback) | tostring);
  def worker($wid; $kind; $label; $state):
    {t: $t, ev: "worker", wid: text($wid; "-"), kind: $kind,
     label: (text($label; $kind) | if . == "" then $kind else .[0:48] end), model: null, state: $state,
     session_id: text(.session_id; "-")};
  def snapshot:
    {t: $t, ev: "snapshot", session_id: text(.session_id; "-"),
     tasks: ((.background_tasks // []) | if type == "array" then map({id, type, status,
       label: (.name // .agent_type // .description // .type)}) else [] end)};
  (.hook_event_name // "") as $event
  | if $event == "SubagentStart" then worker(.agent_id; "subagent"; .agent_type; "running")
    elif $event == "SubagentStop" then worker(.agent_id; "subagent"; .agent_type; "done"), snapshot
    elif $event == "TaskCompleted" then worker(.task_id; "task"; .task_subject; "done")
    elif $event == "Stop" then snapshot
    else empty
    end
' "${payload_file}" >>"${LEDGER}" 2>/dev/null

# Rotation remains inside the writer lock, and the temporary tail lives inside that lock so timeout cleanup removes every owned transient.
rows="$(wc -l <"${LEDGER}" 2>/dev/null)" || rows=0
rows="${rows//[[:space:]]/}"
_normalize_decimal "${rows}" 18 rows || rows=0
if ((rows > MAX_ROWS)); then
    tail -n "${KEEP_ROWS}" -- "${LEDGER}" >"${LOCK}/rotation"
    mv -f -- "${LOCK}/rotation" "${LEDGER}"
fi
