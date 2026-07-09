#!/usr/bin/env bash
# Attention feed for the forge-agents collector: one JSONL row per lifecycle
# event (Notification = needs input, Stop = turn done, SessionEnd = gone).
# Registered at user scope so every session feeds one estate-wide file; the
# collector folds rows into needs_input facts for the bars. Append-only,
# key-name-only, never blocks the session on failure.
set -euo pipefail
state="${XDG_STATE_HOME:-$HOME/.local/state}/forge"
mkdir -p "$state"
jq -c --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{ts: $ts, event: (.hook_event_name // "unknown"), session_id: (.session_id // "-"), cwd: (.cwd // "-")}' \
  >>"$state/agent-attention.jsonl" 2>/dev/null || true
