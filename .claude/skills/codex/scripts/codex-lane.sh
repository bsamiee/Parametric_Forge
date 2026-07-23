#!/usr/bin/env bash
#
# codex-lane.sh — supervised `codex exec` lane: per-call custody, liveness watchdog, JSON receipt
# Usage: codex-lane.sh --task FILE --dir DIR [--law FILE] [--cwd DIR] [--model M] [--effort T]
#                      [--sandbox MODE] [--out FILE] [--web] [--resume THREAD_ID]
#                      [--idle SEC] [--max SEC] [--self-test]
#
set -Eeuo pipefail
shopt -s inherit_errexit nullglob extglob
IFS=$'\n\t'

# --- [CONSTANTS] ------------------------------------------------------------------------

# shellcheck disable=SC2034
readonly VERSION="1.0.0" EX_OK=0 EX_FAIL=1 EX_USAGE=2 EX_IDLE=124 EX_MAX=125
readonly SCRIPT_NAME="${BASH_SOURCE[0]##*/}"
readonly CODEX_BIN="${CODEX_BIN:-${HOME}/.local/bin/codex}"
readonly CODEX_SESSIONS="${CODEX_HOME:-${HOME}/.codex}/sessions"
readonly POLL_SEC=15 GRACE_SEC=10
declare -Ar _SANDBOXES=(["read-only"]=1 ["workspace-write"]=1 ["danger-full-access"]=1)
declare -Ar _EFFORTS=([low]=1 [medium]=1 [high]=1 [xhigh]=1)
declare -Ar _OPT_META=(
    [task]="--task|Task prompt file (absolute)|FILE|"
    [dir]="--dir|Lane artifact home: events.jsonl, stderr.log, receipt.json|DIR|"
    [law]="--law|Developer-instructions file (lane law)|FILE|"
    [cwd]="--cwd|Agent working root|DIR|\$PWD"
    [model]="--model|Model slug deviation|SLUG|config"
    [effort]="--effort|Reasoning tier deviation|TIER|config"
    [sandbox]="--sandbox|Sandbox mode|MODE|read-only"
    [out]="--out|Materialize the final message at this path|FILE|"
    [web]="--web|Enable live web search||off"
    [resume]="--resume|Resume this thread id instead of starting fresh|UUID|"
    [idle]="--idle|Kill after SEC with zero event/rollout growth|SEC|900"
    [max]="--max|Absolute wall ceiling|SEC|10800"
)
TASK="" DIR="" LAW="" CWD="${PWD}" MODEL="" EFFORT="" SANDBOX="read-only" OUT="" WEB=0
RESUME="" IDLE=900 MAX=10800 _CHILD_PID=0 _KILL_REASON=""
declare -a EXTRA=()
declare -a _CLEANUP_STACK=()
declare -i _CLEANING=0

# --- [FUNCTIONS] ------------------------------------------------------------------------

_err() { printf '%s: %s\n' "${SCRIPT_NAME}" "$*" >&2; }
_die() {
    _err "$@"
    exit "${EX_FAIL}"
}
_die_usage() {
    _err "$@"
    _usage >&2
    exit "${EX_USAGE}"
}
_register_cleanup() { _CLEANUP_STACK+=("$1"); }
# shellcheck disable=SC2329  # EXIT-trap invoked
_run_cleanups() {
    ((_CLEANING)) && return
    _CLEANING=1
    local -i i
    # Paradigm exception: LIFO traversal — bash lacks higher-order array iteration
    for ((i = ${#_CLEANUP_STACK[@]} - 1; i >= 0; i--)); do
        eval "${_CLEANUP_STACK[i]}" 2>/dev/null || true
    done
}
_kill_tree() {
    ((_CHILD_PID > 0)) || return 0
    # Snapshot descendants while the tree is intact — no /proc on darwin, pgrep -P is the
    # portable primitive; codex spawns commands into their own process groups a group kill misses.
    local -a descendants=() frontier=("${_CHILD_PID}")
    local head kids kid
    # Paradigm exception: breadth-first descent requires mutable frontier iteration
    while ((${#frontier[@]} > 0)); do
        head="${frontier[0]}"
        frontier=("${frontier[@]:1}")
        kids="$(pgrep -P "${head}" 2>/dev/null || true)"
        [[ -n "${kids}" ]] || continue
        while IFS= read -r kid; do
            descendants+=("${kid}")
            frontier+=("${kid}")
        done <<<"${kids}"
    done
    kill -TERM -- "-${_CHILD_PID}" 2>/dev/null || true
    local -r deadline=$((BASH_MONOSECONDS + GRACE_SEC))
    # Paradigm exception: polling requires mutable iteration
    while ((BASH_MONOSECONDS < deadline)); do
        kill -0 "${_CHILD_PID}" 2>/dev/null || break
        sleep 1
    done
    kill -KILL -- "-${_CHILD_PID}" 2>/dev/null || true
    # Reap escapees the group kill missed — recycled/exited PIDs swallow, GRACE_SEC bounds the risk.
    for kid in "${descendants[@]}"; do
        kill -KILL "${kid}" 2>/dev/null || true
    done
    return 0
}
# shellcheck disable=SC2329  # signal-trap invoked
_on_signal() {
    _KILL_REASON="signal-${BASH_TRAPSIG}"
    _kill_tree
    exit $((128 + BASH_TRAPSIG))
}
_size_sum() {
    local -n _total=$1
    shift
    local f
    _total=0
    for f in "$@"; do
        [[ -f "${f}" ]] && ((_total += $(wc -c <"${f}"))) || true
    done
}
_rollout_of() {
    local -n _path=$1
    local -r thread="$2"
    [[ -z "${thread}" ]] && return 0
    local -a hits=("${CODEX_SESSIONS}"/*/*/*/rollout-*-"${thread}".jsonl)
    ((${#hits[@]} > 0)) && _path="${hits[-1]}"
    return 0
}
_thread_of() {
    local -n _id=$1
    local -r events="$2"
    [[ -s "${events}" ]] || return 0
    _id="$(jq -rs 'map(select(.type == "thread.started")) | first | .thread_id // empty' "${events}" 2>/dev/null || true)"
}
_watch() {
    local -r events="$1" stderr_log="$2"
    local -r start="${BASH_MONOSECONDS}"
    local thread="" rollout="" last_size=-1 size=0
    local stamp="${BASH_MONOSECONDS}"
    # Paradigm exception: supervision poll — mutable iteration is the resource protocol
    while kill -0 "${_CHILD_PID}" 2>/dev/null; do
        sleep "${POLL_SEC}"
        [[ -z "${thread}" ]] && _thread_of thread "${events}"
        [[ -z "${rollout}" ]] && _rollout_of rollout "${thread}"
        _size_sum size "${events}" "${stderr_log}" "${rollout}"
        ((size != last_size)) && {
            last_size="${size}"
            stamp="${BASH_MONOSECONDS}"
        }
        if ((BASH_MONOSECONDS - stamp >= IDLE)); then
            _KILL_REASON="idle-timeout"
            _kill_tree
            break
        fi
        if ((BASH_MONOSECONDS - start >= MAX)); then
            _KILL_REASON="max-timeout"
            _kill_tree
            break
        fi
    done
}
_receipt() {
    local -r events="$1" receipt="$2" child_rc="$3" duration="$4" stderr_log="$5"
    local thread=""
    _thread_of thread "${events}"
    local reason="crash" ok=false
    local terminal
    terminal="$(jq -rs 'map(.type) | map(select(. == "turn.completed" or . == "turn.failed")) | last // empty' "${events}" 2>/dev/null)" || terminal=""
    [[ "${terminal}" == "turn.completed" && "${child_rc}" == "0" ]] && {
        reason="completed"
        ok=true
    }
    [[ "${terminal}" == "turn.failed" ]] && reason="turn-failed"
    [[ -n "${_KILL_REASON}" ]] && reason="${_KILL_REASON}"
    local tmp
    tmp="$(mktemp "${receipt}.XXXXXX")"
    jq -ncs \
        --argjson ok "${ok}" --arg reason "${reason}" --arg thread "${thread}" \
        --argjson exit "${child_rc}" --argjson duration "${duration}" \
        --arg events "${events}" --arg stderr "${stderr_log}" --arg report "${OUT}" \
        '{ok: $ok, reason: $reason, thread_id: (if $thread == "" then null else $thread end),
          exit: $exit, duration_s: $duration, events: $events, stderr: $stderr,
          report: (if $report == "" then null else $report end),
          failure: (if $reason == "turn-failed"
                    then (input | map(select(.type == "turn.failed")) | last | .error.message // "turn failed")
                    else null end),
          usage: (input | map(select(.type == "turn.completed")) | last | .usage // null)}' \
        "${events}" "${events}" >"${tmp}" 2>/dev/null ||
        printf '{"ok":false,"reason":"%s","thread_id":null,"exit":%s,"duration_s":%s,"events":"%s","stderr":"%s","report":null,"failure":"receipt composition failed","usage":null}\n' \
            "${reason}" "${child_rc}" "${duration}" "${events}" "${stderr_log}" >"${tmp}"
    mv "${tmp}" "${receipt}"
    cat "${receipt}"
}
_build_argv() {
    local -n _argv=$1
    _argv=("${CODEX_BIN}" exec --json -c approval_policy=never)
    [[ -n "${MODEL}" ]] && _argv+=(-m "${MODEL}")
    [[ -n "${EFFORT}" ]] && _argv+=(-c "model_reasoning_effort=\"${EFFORT}\"")
    [[ -n "${LAW}" ]] && _argv+=(-c "developer_instructions=$(<"${LAW}")")
    ((WEB)) && _argv+=(-c 'web_search="live"')
    [[ -n "${OUT}" ]] && _argv+=(-o "${OUT}")
    ((${#EXTRA[@]} > 0)) && _argv+=("${EXTRA[@]}")
    [[ -n "${RESUME}" ]] && {
        _argv+=(-c "sandbox_mode=\"${SANDBOX}\"" resume "${RESUME}" "$(<"${TASK}")")
        return 0
    }
    _argv+=(-s "${SANDBOX}" -C "${CWD}" "$(<"${TASK}")")
}

# --- [PARSER] ---------------------------------------------------------------------------

_usage() {
    printf '%s v%s — supervised codex exec lane with liveness watchdog and JSON receipt\n' \
        "${SCRIPT_NAME}" "${VERSION}"
    printf '\nUSAGE: %s --task FILE --dir DIR [OPTIONS]\n\nOPTIONS:\n' "${SCRIPT_NAME}"
    local key short desc value_name default
    for key in task dir law cwd model effort sandbox out web resume idle max; do
        IFS='|' read -r short desc value_name default <<<"${_OPT_META[${key}]}"
        printf '  %-18s %s%s\n' "${short}${value_name:+ ${value_name}}" "${desc}" \
            "${default:+ (default: ${default})}"
    done
    printf '  %-18s %s\n' "--self-test" "Run smoke tests" "-h, --help" "Show this help" \
        "-- ARGS..." "Pass the remainder to codex exec verbatim"
}
_parse_args() {
    while (($# > 0)); do
        case "$1" in
            -h | --help)
                _usage
                exit 0
                ;;
            --self-test)
                _self_test
                exit 0
                ;;
            --task) TASK="${2:?--task requires a file}" && shift 2 ;;
            --dir) DIR="${2:?--dir requires a path}" && shift 2 ;;
            --law) LAW="${2:?--law requires a file}" && shift 2 ;;
            --cwd) CWD="${2:?--cwd requires a path}" && shift 2 ;;
            --model) MODEL="${2:?--model requires a slug}" && shift 2 ;;
            --effort) EFFORT="${2:?--effort requires a tier}" && shift 2 ;;
            --sandbox) SANDBOX="${2:?--sandbox requires a mode}" && shift 2 ;;
            --out) OUT="${2:?--out requires a path}" && shift 2 ;;
            --web) WEB=1 && shift ;;
            --resume) RESUME="${2:?--resume requires a thread id}" && shift 2 ;;
            --idle) IDLE="${2:?--idle requires seconds}" && shift 2 ;;
            --max) MAX="${2:?--max requires seconds}" && shift 2 ;;
            --)
                shift
                EXTRA=("$@")
                break
                ;;
            *) _die_usage "Unknown argument: $1" ;;
        esac
    done
    [[ -f "${TASK}" ]] || _die_usage "--task file missing: '${TASK}'"
    [[ -n "${DIR}" ]] || _die_usage "--dir is required"
    [[ -z "${LAW}" || -f "${LAW}" ]] || _die_usage "--law file missing: '${LAW}'"
    [[ -v _SANDBOXES["${SANDBOX}"] ]] || _die_usage "Invalid --sandbox: '${SANDBOX}'"
    [[ -z "${EFFORT}" ]] || [[ -v _EFFORTS["${EFFORT}"] ]] || _die_usage "Invalid --effort: '${EFFORT}'"
    [[ "${IDLE}" =~ ^[0-9]+$ && "${MAX}" =~ ^[0-9]+$ ]] || _die_usage "--idle/--max take integer seconds"
}

# --- [TESTING] --------------------------------------------------------------------------

_assert_eq() { [[ "$1" == "$2" ]] || _die "ASSERT ${FUNCNAME[1]}:${BASH_LINENO[0]}: '${1}' != '${2}'"; }
_self_test() {
    local -r work="$(mktemp -d)"
    _register_cleanup "rm -rf '${work}'"
    printf '%s\n' \
        '{"type":"thread.started","thread_id":"0000-test-id"}' '{"type":"turn.started"}' \
        '{"type":"item.completed","item":{"id":"item_0","type":"error","message":"skills budget"}}' \
        '{"type":"item.completed","item":{"id":"item_1","type":"agent_message","text":"OK"}}' \
        '{"type":"turn.completed","usage":{"input_tokens":1,"cached_input_tokens":0,"output_tokens":1,"reasoning_output_tokens":0}}' \
        >"${work}/events.jsonl"
    local thread=""
    _thread_of thread "${work}/events.jsonl"
    _assert_eq "${thread}" "0000-test-id"
    local receipt
    receipt="$(_receipt "${work}/events.jsonl" "${work}/receipt.json" 0 7 "${work}/stderr.log")"
    _assert_eq "$(jq -r '.ok' <<<"${receipt}")" "true"
    _assert_eq "$(jq -r '.reason' <<<"${receipt}")" "completed"
    _assert_eq "$(jq -r '.usage.input_tokens' <<<"${receipt}")" "1"
    _KILL_REASON="idle-timeout"
    receipt="$(_receipt "${work}/events.jsonl" "${work}/receipt.json" 137 900 "${work}/stderr.log")"
    _assert_eq "$(jq -r '.ok' <<<"${receipt}")" "false"
    _assert_eq "$(jq -r '.reason' <<<"${receipt}")" "idle-timeout"
    _KILL_REASON=""
    TASK="${work}/events.jsonl" MODEL="m" EFFORT="low" SANDBOX="read-only" CWD="/tmp" EXTRA=(--ephemeral)
    local -a argv=()
    _build_argv argv
    _assert_eq "${argv[1]}" "exec"
    _assert_eq "${argv[2]}" "--json"
    _assert_eq "${argv[-6]}" "--ephemeral"
    printf 'self-test passed\n'
}

# --- [EXPORT] ---------------------------------------------------------------------------

_main() {
    _parse_args "$@"
    readonly TASK DIR LAW CWD MODEL EFFORT SANDBOX OUT WEB RESUME IDLE MAX
    [[ -x "${CODEX_BIN}" ]] || _die "codex binary not executable: ${CODEX_BIN}"
    mkdir -p "${DIR}"
    local -r events="${DIR}/events.jsonl" stderr_log="${DIR}/stderr.log" receipt="${DIR}/receipt.json"
    rm -f "${events}" "${stderr_log}" "${receipt}" ${OUT:+"${OUT}"}
    local -a argv=()
    _build_argv argv
    local -r start="${BASH_MONOSECONDS}"
    set -m
    "${argv[@]}" </dev/null >"${events}" 2>"${stderr_log}" &
    _CHILD_PID=$!
    set +m
    _register_cleanup "kill -KILL -- '-${_CHILD_PID}' 2>/dev/null || true"
    _watch "${events}" "${stderr_log}"
    local -i child_rc=0
    wait "${_CHILD_PID}" 2>/dev/null || child_rc=$?
    _CHILD_PID=0
    local -r duration=$((BASH_MONOSECONDS - start))
    local body reason
    body="$(_receipt "${events}" "${receipt}" "${child_rc}" "${duration}" "${stderr_log}")"
    printf '%s\n' "${body}"
    reason="$(jq -r '.reason' <<<"${body}")"
    case "${reason}" in
        completed) exit "${EX_OK}" ;;
        idle-timeout) exit "${EX_IDLE}" ;;
        max-timeout) exit "${EX_MAX}" ;;
        *) exit "${EX_FAIL}" ;;
    esac
}
trap '_on_signal' TERM INT HUP
trap '_run_cleanups' EXIT
_main "$@"
