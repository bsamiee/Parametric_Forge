#!/usr/bin/env bash
# Attention feed for the forge-agents collector: one JSONL row per lifecycle
# event (Notification = needs input, Stop = turn done, SessionEnd = gone).
# Rows carry the emitting session's terminal identity (zellij session/pane,
# wezterm pane, controlling tty) so `forge-agents focus` can route a
# notification click back to the exact pane. Registered at user scope so every
# session feeds one estate-wide file. Append-only, never blocks on failure.
set -euo pipefail
state="${XDG_STATE_HOME:-$HOME/.local/state}/forge"
mkdir -p "$state"
tty="$(ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' ' || true)"
[ "$tty" = "??" ] && tty=""
jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg term "${TERM_PROGRAM:-}" --arg wp "${WEZTERM_PANE:-}" \
    --arg zs "${ZELLIJ_SESSION_NAME:-}" --arg zp "${ZELLIJ_PANE_ID:-}" \
    --arg tty "$tty" \
    '{ts: $ts, event: (.hook_event_name // "unknown"), session_id: (.session_id // "-"), cwd: (.cwd // "-"),
      term: $term, wezterm_pane: $wp, zellij_session: $zs, zellij_pane: $zp, tty: $tty}' \
    >>"$state/agent-attention.jsonl" 2>/dev/null || true
