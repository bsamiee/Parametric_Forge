#!/usr/bin/env bash
# Attention feed for the forge-agents collector: one JSONL row per lifecycle
# event, carrying the emitting session's terminal identity so `forge-agents
# focus` routes a notification click back to the exact pane. Append-only;
# any failure exits 0 so the hook can never block the harness.
set -euo pipefail
trap 'exit 0' ERR

feed="${FORGE_ATTENTION_FEED:-${XDG_STATE_HOME:-$HOME/.local/state}/forge/agent-attention.jsonl}"
max_rows="${FORGE_ATTENTION_MAX_ROWS:-4000}"
keep_rows="${FORGE_ATTENTION_KEEP_ROWS:-1000}"
mkdir -p "${feed%/*}"

# Terminal identity: the hook's own controlling tty, else the spawning
# agent's; "??" (no controlling terminal) admits as empty.
tty="$(/bin/ps -o tty= -p $$ 2>/dev/null | tr -d ' ' || true)"
[ -n "$tty" ] && [ "$tty" != "??" ] ||
    tty="$(/bin/ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' ' || true)"
[ "$tty" != "??" ] || tty=""

TZ=UTC0 printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' "$EPOCHSECONDS"
jq -c --arg ts "$ts" \
    --arg term "${TERM_PROGRAM:-}" --arg wp "${WEZTERM_PANE:-}" \
    --arg zs "${ZELLIJ_SESSION_NAME:-}" --arg zp "${ZELLIJ_PANE_ID:-}" \
    --arg tty "$tty" \
    '{ts: $ts, event: (.hook_event_name // "unknown"), session_id: (.session_id // "-"), cwd: (.cwd // "-"),
    term: $term, wezterm_pane: $wp, zellij_session: $zs, zellij_pane: $zp, tty: $tty}' \
    >>"$feed" 2>/dev/null

# Size-gated self-rotation, lock-free: rows are advisory telemetry, so a row a
# concurrent appender loses to the atomic rename self-heals on its next event.
rows="$(wc -l <"$feed")"
if [ "$rows" -gt "$max_rows" ]; then
    tail -n "$keep_rows" "$feed" >"$feed.rot.$$"
    mv -f "$feed.rot.$$" "$feed"
fi
