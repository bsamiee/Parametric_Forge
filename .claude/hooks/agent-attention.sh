#!/usr/bin/env bash
# Attention feed for the forge-agents collector: one JSONL row per MAIN-AGENT lifecycle event, carrying the emitting session's terminal identity
# (session_id -> zellij_session/zellij_pane/wezterm_pane/tty — the shared identity map both the bar cell and the answer channel route by) plus the
# verbatim Notification prompt text the banner and alerter render. The gate is the mirror-image of the fleet hook: rows carrying agent_id (subagent
# chatter) and non-lifecycle events drop at emission, so the feed stays pure signal and the collector fold is a per-session max_by(.ts). PostToolUse
# stays on the roster because it is the fold's only clearing event after a permission-prompt approval (no UserPromptSubmit fires there). Rows carry a
# `source` discriminator (hook here; the WezTerm bell arm appends source=bell rows on the same schema) so the collector folds per-source policy.
# Append-only; any failure exits 0 so the hook can never block the harness.
set -Eeuo pipefail
shopt -s inherit_errexit 2>/dev/null || true
trap 'exit 0' ERR HUP INT TERM
umask 077

_resolve_bin() {
    local -r name="$1" out_name="$2"
    local candidate=""
    candidate="$(command -v "$name" 2>/dev/null || true)"
    if [[ -x "$candidate" && ! -d "$candidate" ]]; then
        printf -v "$out_name" '%s' "$candidate"
        return 0
    fi
    local -ra candidates=(
        "/etc/profiles/per-user/${USER:-${LOGNAME:-}}/bin/$name"
        "${HOME:-}/.nix-profile/bin/$name"
        "/run/current-system/sw/bin/$name"
        "/nix/var/nix/profiles/default/bin/$name"
    )
    for candidate in "${candidates[@]}"; do
        if [[ -x "$candidate" && ! -d "$candidate" ]]; then
            printf -v "$out_name" '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

owner_bin=""
_resolve_bin forge-agent-attention owner_bin || true
if [[ -z "${_FORGE_ATTENTION_OWNER:-}" && -n "$owner_bin" && ! "$owner_bin" -ef "$0" ]]; then
    export _FORGE_ATTENTION_OWNER=1
    "$owner_bin" "$@" || true
    exit 0
fi

timeout_bin=""
flock_bin=""
forge_agents_bin=""
jq_bin=""
_resolve_bin timeout timeout_bin || true
_resolve_bin flock flock_bin || true
_resolve_bin forge-agents forge_agents_bin || true
_resolve_bin jq jq_bin || true
readonly owner_bin timeout_bin flock_bin forge_agents_bin jq_bin
[[ -n "$timeout_bin" && -n "$flock_bin" && -n "$jq_bin" ]] || exit 0
((BASH_VERSINFO[0] >= 5)) || exit 0

# Whole-body deadline: one parent wrapper re-enters the hook under timeout so no stage can hold the harness beyond 4s, while every timeout outcome
# still returns success. Bash 5.3 backs sub-64K here-docs/here-strings with a self-held pipe that can deadlock pre-exec under kernel pipe-buffer
# exhaustion, so payload-scale data enters through bounded stdin once and then rides a temp file into every jq below.
if [[ -z "${_FORGE_HOOK_DEADLINE:-}" && -n "$timeout_bin" ]]; then
    export _FORGE_HOOK_DEADLINE=1
    "$timeout_bin" -k 1 4 "$BASH" "$0" "$@" >/dev/null 2>&1 || true
    exit 0
fi

feed="${FORGE_ATTENTION_FEED:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/agent-attention.jsonl}"
max_rows_raw="${FORGE_ATTENTION_MAX_ROWS:-4000}"
keep_rows_raw="${FORGE_ATTENTION_KEEP_ROWS:-1000}"
[[ "$max_rows_raw" =~ ^0*([1-9][0-9]{0,5})$ ]] || exit 0
max_rows=$((10#${BASH_REMATCH[1]}))
[[ "$keep_rows_raw" =~ ^0*([1-9][0-9]{0,5})$ ]] || exit 0
keep_rows=$((10#${BASH_REMATCH[1]}))
((max_rows <= 100000 && keep_rows <= max_rows)) || exit 0
feed_dir="${feed%/*}"
[[ "$feed_dir" == "$feed" ]] && feed_dir="."
pf=""
row=""
rotation=""

_cleanup() {
    [[ -z "${pf:-}" ]] || rm -f -- "$pf" 2>/dev/null || true
    [[ -z "${row:-}" ]] || rm -f -- "$row" 2>/dev/null || true
    [[ -z "${rotation:-}" ]] || rm -f -- "$rotation" 2>/dev/null || true
}
trap _cleanup EXIT

# Bounded stdin read: one C-locale read admits at most 1 MiB plus one sentinel byte and waits at most 1s for EOF; oversize or incomplete JSON drops.
payload=""
LC_ALL=C IFS= read -r -t 1 -N 1048577 payload || true
[[ -n "$payload" ]] || exit 0
((${#payload} <= 1048576)) || exit 0
pf="$(mktemp "${TMPDIR:-/tmp}/forge-attention.XXXXXX")"
row="$(mktemp "${TMPDIR:-/tmp}/forge-attention-row.XXXXXX")"
printf '%s' "$payload" >"$pf"

# Payload admission before any telemetry fork: main agent only (agent_id absent) on the lifecycle roster — Notification opens WAITING, the other five
# clear or retire the session in the collector's lifecycle fold. A dropped payload exits before ps/mkdir ever run, so subagent churn costs one jq.
"$jq_bin" -e '((.agent_id // "") == "")
  and ((.hook_event_name // "") | IN("Notification", "Stop", "UserPromptSubmit", "PostToolUse", "SessionStart", "SessionEnd"))' \
    "$pf" >/dev/null 2>&1 || exit 0
mkdir -p "$feed_dir"

# Terminal identity: the hook's own controlling tty, else the spawning agent's; no-controlling-terminal ("??" BSD, "?" procps) admits as empty.
# PATH-resolved ps: /bin/ps is a Darwin fact and the hook runs on every host.
tty="$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' || true)"
{ [[ -n "$tty" && "$tty" != "??" && "$tty" != "?" ]]; } ||
    tty="$(ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' ' || true)"
case "$tty" in "?" | "??") tty="" ;; esac

# Message rides verbatim into the banner, alerter, and bar toast, so C0/C1 controls (newlines, ANSI escapes) fold to single spaces at
# capture — the feed carries one-line prompt text no downstream renderer can be steered by.
TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
"$jq_bin" -c --arg ts "$ts" \
    --arg term "${TERM_PROGRAM:-}" --arg wp "${WEZTERM_PANE:-}" \
    --arg zs "${ZELLIJ_SESSION_NAME:-}" --arg zp "${ZELLIJ_PANE_ID:-}" \
    --arg tty "$tty" \
    $'{ts: $ts, source: "hook", event: .hook_event_name, session_id: (.session_id // "-"), cwd: (.cwd // "-"),
    message: ((.message // "") | tostring | gsub("[[:cntrl:]]+"; " ") | .[0:400]),
    term: $term, wezterm_pane: $wp, zellij_session: $zs, zellij_pane: $zp, tty: $tty}' \
    "$pf" >"$row" 2>/dev/null

# One bounded writer lock owns append and rotation as a single transaction, so concurrent lifecycle rows cannot land on the pre-rename inode.
[[ -n "$flock_bin" ]] || exit 0
exec {writer_fd}>"${feed}.writer.lock"
"$flock_bin" -w 1 "$writer_fd" || exit 0
<"$row" cat >>"$feed"
rows="$(wc -l <"$feed")"
rows="${rows//[[:space:]]/}"
if [[ "$rows" =~ ^(0|[1-9][0-9]{0,7})$ ]] && ((10#$rows > max_rows)); then
    rotation="$(mktemp "${feed}.rot.XXXXXX")"
    tail -n "$keep_rows" -- "$feed" >"$rotation"
    mv -f -- "$rotation" "$feed"
    rotation=""
fi
exec {writer_fd}>&-

# Edge kick: the nonblocking lock makes admission atomic, its descriptor survives into the disowned collector and therefore admits at most one queued
# body, and the epoch stamp suppresses completed bursts for 5s. The inner timeout bounds the collector independently of this hook's parent deadline.
kick="$feed_dir/.collect-kick"
if [[ -n "$flock_bin" && -n "$timeout_bin" && -n "$forge_agents_bin" ]]; then
    exec {kick_fd}>"${kick}.lock"
    if "$flock_bin" -n "$kick_fd"; then
        last_kick=0
        [[ ! -f "$kick" ]] || IFS= read -r last_kick <"$kick" || last_kick=0
        [[ "$last_kick" =~ ^(0|[1-9][0-9]*)$ ]] || last_kick=0
        now="$EPOCHSECONDS"
        if ((now < last_kick || now - last_kick >= 5)); then
            printf '%s\n' "$now" >"$kick"
            "$timeout_bin" -k 5 30 "$forge_agents_bin" collect >/dev/null 2>&1 </dev/null &
            disown 2>/dev/null || true
        fi
    fi
    exec {kick_fd}>&-
fi
