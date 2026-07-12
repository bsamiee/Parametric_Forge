#!/usr/bin/env bash
# External-worker delegation emitter. Every invocation admits one bounded worker row, serializes append and rotation with the lifecycle-hook writer,
# and fails open when malformed input, dead ownership metadata, or filesystem contention would otherwise interfere with the calling worker.
set -Eeuo pipefail
shopt -s inherit_errexit

[[ -n "${FORGE_FLEET_DEBUG:-}" ]] || trap 'exit 0' ERR

readonly LEDGER="${FORGE_FLEET_LEDGER:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/delegation.jsonl}"
readonly MAX_ROWS_RAW="${FORGE_FLEET_MAX_ROWS:-4000}" KEEP_ROWS_RAW="${FORGE_FLEET_KEEP_ROWS:-1000}"
readonly MAX_INPUT_BYTES=1048576 LOCK="${LEDGER}.lock" REAPER="${LEDGER}.lock.reap" STALE_SECONDS=60
ledger_dir="${LEDGER%/*}"
[[ "${ledger_dir}" != "${LEDGER}" ]] || ledger_dir=.
lock_owned=0 reaper_owned=0 rotation="" LOCK_TOKEN="" REAPER_TOKEN="" MAX_ROWS="" KEEP_ROWS=""

_cleanup() {
    [[ -z "${rotation}" ]] || rm -f -- "${rotation}" 2>/dev/null || true
    ((reaper_owned)) && _release_reaper || true
    ((lock_owned)) && _release_lock || true
}
trap '_cleanup' EXIT
trap 'exit 0' TERM INT HUP

# shellcheck source=forge-fleet-lock.sh
source "${FORGE_FLEET_LOCK_LIB:-${BASH_SOURCE[0]%/*}/forge-fleet-lock.sh}"

_take_value() {
    (($# >= 2)) || return 1
    REPLY="$2"
}

session="${FORGE_FLEET_SESSION:-${CLAUDE_CODE_SESSION_ID:-}}"
kind="external" label="" model="" effort="" state="running" wid="" pid="${FORGE_FLEET_PID:-}"
(($# <= 32)) || exit 0
while (($# > 0)); do
    case "$1" in
        --kind)
            _take_value "$@" || exit 0
            kind="${REPLY}"
            shift 2
            ;;
        --label)
            _take_value "$@" || exit 0
            label="${REPLY}"
            shift 2
            ;;
        --model)
            _take_value "$@" || exit 0
            model="${REPLY}"
            shift 2
            ;;
        --effort)
            _take_value "$@" || exit 0
            effort="${REPLY}"
            shift 2
            ;;
        --state)
            _take_value "$@" || exit 0
            case "${REPLY}" in start) state="running" ;; stop) state="done" ;; *) state="${REPLY}" ;; esac
            shift 2
            ;;
        --wid)
            _take_value "$@" || exit 0
            wid="${REPLY}"
            shift 2
            ;;
        --pid)
            _take_value "$@" || exit 0
            pid="${REPLY}"
            shift 2
            ;;
        --session)
            _take_value "$@" || exit 0
            session="${REPLY}"
            shift 2
            ;;
        *) shift ;;
    esac
done
[[ -n "${wid}" ]] || wid="${kind}-$$"

_normalize_decimal "${MAX_ROWS_RAW}" 6 MAX_ROWS || exit 0
_normalize_decimal "${KEEP_ROWS_RAW}" 6 KEEP_ROWS || exit 0
((MAX_ROWS > 0 && MAX_ROWS <= 100000 && KEEP_ROWS > 0)) || exit 0
((KEEP_ROWS <= MAX_ROWS)) || exit 0
readonly MAX_ROWS KEEP_ROWS
((\
${#session} + ${#kind} + ${#label} + ${#model} + ${#effort} + ${#state} + ${#wid} + ${#pid} <= MAX_INPUT_BYTES)) ||
    exit 0

mkdir -p -- "${ledger_dir}"
_acquire_lock || exit 0
jq -nc --argjson t "${EPOCHSECONDS}" \
    --arg wid "${wid}" --arg kind "${kind}" --arg label "${label}" --arg model "${model}" --arg effort "${effort}" \
    --arg state "${state}" --arg pid "${pid}" --arg session "${session}" '
      {t: $t, ev: "worker", wid: $wid[0:128], kind: $kind[0:48], label: ($label | if . == "" then null else .[0:48] end),
       model: ($model | if . == "" then null else .[0:128] end), effort: ($effort | if . == "" then null else .[0:48] end), state: $state[0:48],
       pid: (if $pid == "" then null else (($pid | tonumber?) // null) end), session_id: (if $session == "" then null else $session[0:128] end)}
    ' >>"${LEDGER}" 2>/dev/null

rows="$(wc -l <"${LEDGER}" 2>/dev/null)" || rows=0
rows="${rows//[[:space:]]/}"
_normalize_decimal "${rows}" 18 rows || rows=0
if ((rows > MAX_ROWS)); then
    rotation="${LOCK}/rotation"
    tail -n "${KEEP_ROWS}" -- "${LEDGER}" >"${rotation}"
    mv -f -- "${rotation}" "${LEDGER}"
    rotation=""
fi
