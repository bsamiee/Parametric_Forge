#!/usr/bin/env bash
# Codex adapter: pipe the Codex payload into one canonical hook body, then emit the exact Codex dialect per event. The adapter is
# the SOLE dialect owner; the body is dialect-blind and ALWAYS emits Claude dialect. Wire in .codex/hooks.json (or config.toml).
# Exit-2 blocks pass through natively on the tool, prompt, AND Stop-family events; only stdout-JSON rewrites need a per-event branch.
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

# Exit 2: portable across both providers on the tool, prompt, AND Stop-family events; Codex Stop/SubagentStop honor exit-2 + stderr.
if ((code == 2)); then
    cat "${errfile}" >&2
    exit 2
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
      elif $event == "PreToolUse" and ((.hookSpecificOutput.permissionDecision // "") | . == "defer" or . == "ask") then
        .hookSpecificOutput.permissionDecision = "deny"
      elif $event == "PostToolUse" and (.hookSpecificOutput.updatedToolOutput != null) then
        (.hookSpecificOutput.updatedToolOutput) as $o
        | {decision: "block", reason: (if ($o | type) == "string" then $o
            elif ($o | type) == "object" then (([($o.stdout // ""), ($o.stderr // "")] | map(select(. != "")) | join("\n")) as $t
              | if $t == "" then ($o | tojson) else $t end)
            else ($o | tojson) end)}
      else . end
'
