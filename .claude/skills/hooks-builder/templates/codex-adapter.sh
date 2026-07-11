#!/usr/bin/env bash
# Codex adapter: pipe the Codex payload into one canonical hook body, then emit the exact Codex dialect per event. The adapter is
# the SOLE dialect owner; the body is dialect-blind and ALWAYS emits Claude dialect. Wire in .codex/hooks.json (or config.toml).
# Exit-2 blocks pass through on PreToolUse/PostToolUse/UserPromptSubmit; a Stop-family exit-2 re-emits as decision JSON.
set -Eeuo pipefail
shopt -s inherit_errexit
_on_err() { printf 'adapter error: exit %d at line %d: %s\n' "$?" "${LINENO}" "${BASH_COMMAND}" >&2; }
trap _on_err ERR

readonly BODY="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}/.claude/hooks/canonical-body.py"

payload="$(cat)"
event="$(jq -r '.hook_event_name // ""' <<<"${payload}")"
export HOOK_PROVIDER="codex" # routing/telemetry tag only — the body reads it for its event envelope's source, never to shape stdout

errfile="$(mktemp)"
trap 'rm -f "${errfile}"' EXIT
trap - ERR # the body's non-zero exit is captured intent, not an error; drop the ERR trap for the fenced call, restore after
set +e
out="$(printf '%s' "${payload}" | "${BODY}" 2>"${errfile}")"
code=$?
set -e
trap _on_err ERR

# Exit 2: portable on the tool and prompt events; the Stop family blocks via decision JSON, synthesized from stderr.
if ((code == 2)); then
    case "${event}" in
        Stop | SubagentStop)
            jq -nc --arg reason "$(cat "${errfile}")" '{decision: "block", reason: $reason}'
            exit 0
            ;;
        *)
            cat "${errfile}" >&2
            exit 2
            ;;
    esac
fi
if ((code != 0)); then
    cat "${errfile}" >&2
    exit "${code}" # non-blocking error passes through unshaped
fi

# Exit 0: rewrite the Claude stdout dialect into Codex's per-event shape. Empty output stays empty (pass-through).
[[ -z "${out}" ]] && exit 0
printf '%s' "${out}" | jq -c --arg event "${event}" '
    del(.terminalSequence)
    | if $event == "PermissionRequest" and (.hookSpecificOutput.permissionDecision // "") != "" then
        {hookSpecificOutput: {hookEventName: "PermissionRequest",
                              decision: {behavior: (if .hookSpecificOutput.permissionDecision == "allow" then "allow" else "deny" end),
                                         message: (.hookSpecificOutput.permissionDecisionReason // "")}}}
      elif $event == "PermissionRequest" and (.hookSpecificOutput.decision // null) != null then
        {hookSpecificOutput: {hookEventName: "PermissionRequest",
                              decision: {behavior: (.hookSpecificOutput.decision.behavior // "deny"),
                                         message: (.hookSpecificOutput.decision.message // "")}}}
      elif $event == "PreToolUse" and (.hookSpecificOutput.permissionDecision // "") == "defer" then
        .hookSpecificOutput.permissionDecision = "ask"
      else . end
'
