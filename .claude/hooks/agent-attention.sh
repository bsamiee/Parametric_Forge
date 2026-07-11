#!/usr/bin/env bash
# Attention feed for the forge-agents collector: one JSONL row per MAIN-AGENT lifecycle event, carrying the emitting session's terminal identity
# (session_id -> zellij_session/zellij_pane/wezterm_pane/tty — the shared identity map both the bar cell and the answer channel route by) plus the
# verbatim Notification prompt text the banner and alerter render. The gate is the mirror-image of the fleet hook: rows carrying agent_id (subagent
# chatter) and non-lifecycle events drop at emission, so the feed stays pure signal and the collector fold is a per-session max_by(.ts). PostToolUse
# stays on the roster because it is the fold's only clearing event after a permission-prompt approval (no UserPromptSubmit fires there). Rows carry a
# `source` discriminator (hook here; the WezTerm bell arm appends source=bell rows on the same schema) so the collector folds per-source policy.
# Append-only; any failure exits 0 so the hook can never block the harness.
set -Eeuo pipefail
trap 'exit 0' ERR

# Whole-body deadline: re-exec under timeout so no stage — stdin read, jq, feed append — can strand a hook body past the budget. bash-5.3 backs
# sub-64K here-docs/here-strings with a pipe the redirecting process holds both ends of; under kernel pipe-buffer exhaustion that write deadlocks
# pre-exec, so the payload rides a temp FILE into every jq below and the deadline forecloses any residual wedge.
if [ -z "${_FORGE_HOOK_DEADLINE:-}" ] && command -v timeout >/dev/null 2>&1; then
    _FORGE_HOOK_DEADLINE=1 exec timeout -k 5 45 "$0" "$@"
fi

feed="${FORGE_ATTENTION_FEED:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/agent-attention.jsonl}"
max_rows="${FORGE_ATTENTION_MAX_ROWS:-4000}"
keep_rows="${FORGE_ATTENTION_KEEP_ROWS:-1000}"

# Bounded stdin read: the read builtin consumes to EOF (or the 20s guard when a harness holds the pipe open) with no cat fork and no
# command-substitution pipe; a timeout keeps whatever partial payload arrived.
payload=""
IFS= read -r -t 20 -d '' payload || true
[ -n "$payload" ] || exit 0
pf="$(mktemp "${TMPDIR:-/tmp}/forge-attention.XXXXXX")"
trap 'rm -f "$pf"' EXIT
printf '%s' "$payload" >"$pf"

# Admission gate before any fork: main agent only (agent_id absent) on the lifecycle roster — Notification opens WAITING, the other five clear or
# retire the session in the collector's lifecycle fold. A dropped payload exits before ps/mkdir ever run, so subagent tool churn costs one jq.
jq -e '((.agent_id // "") == "")
  and ((.hook_event_name // "") | IN("Notification", "Stop", "UserPromptSubmit", "PostToolUse", "SessionStart", "SessionEnd"))' \
    "$pf" >/dev/null 2>&1 || exit 0
mkdir -p "${feed%/*}"

# Terminal identity: the hook's own controlling tty, else the spawning agent's; no-controlling-terminal ("??" BSD, "?" procps) admits as empty.
# PATH-resolved ps: /bin/ps is a Darwin fact and the hook runs on every host.
tty="$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' || true)"
{ [ -n "$tty" ] && [ "$tty" != "??" ] && [ "$tty" != "?" ]; } ||
    tty="$(ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' ' || true)"
case "$tty" in "?" | "??") tty="" ;; esac

# Message rides verbatim into the banner, alerter, and bar toast, so C0/C1 controls (newlines, ANSI escapes) fold to single spaces at
# capture — the feed carries one-line prompt text no downstream renderer can be steered by.
TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
jq -c --arg ts "$ts" \
    --arg term "${TERM_PROGRAM:-}" --arg wp "${WEZTERM_PANE:-}" \
    --arg zs "${ZELLIJ_SESSION_NAME:-}" --arg zp "${ZELLIJ_PANE_ID:-}" \
    --arg tty "$tty" \
    '{ts: $ts, source: "hook", event: .hook_event_name, session_id: (.session_id // "-"), cwd: (.cwd // "-"),
    message: ((.message // "") | tostring | gsub("[[:cntrl:]]+"; " ") | .[0:400]),
    term: $term, wezterm_pane: $wp, zellij_session: $zs, zellij_pane: $zp, tty: $tty}' \
    "$pf" >>"$feed" 2>/dev/null

# Edge kick, stamp-throttled to 5s: a fresh lifecycle row re-folds the collector now (flock-serialized there), so the pane mark, bar cell,
# and banner track the event at second latency instead of the 60s launchd tick; a host without forge-agents still lands the row for later.
# The kick is hard-capped and disowned: the collector serializes on a flock, so under multi-agent load an uncapped kick accumulates blocked
# processes faster than the drain — the timeout bounds each kick's life and disown severs it from the harness's child accounting.
kick="${feed%/*}/.collect-kick"
if [ -z "$(find "$kick" -newermt '-5 seconds' 2>/dev/null)" ]; then
    : >"$kick"
    if command -v forge-agents >/dev/null 2>&1; then
        kick_cmd=(forge-agents collect)
        command -v timeout >/dev/null 2>&1 && kick_cmd=(timeout 30 forge-agents collect)
        "${kick_cmd[@]}" >/dev/null 2>&1 </dev/null &
        disown 2>/dev/null || true
    fi
fi

# Size-gated self-rotation, lock-free: advisory telemetry, so a row a concurrent appender loses to the atomic rename self-heals on its next event.
rows="$(wc -l <"$feed")"
if [ "$rows" -gt "$max_rows" ]; then
    tail -n "$keep_rows" "$feed" >"$feed.rot.$$"
    mv -f "$feed.rot.$$" "$feed"
fi
