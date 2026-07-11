---
name: hooks-builder
description: >-
    Builds Claude Code and Codex hooks as one discipline — command, HTTP, MCP-tool, prompt, and
    agent handlers across the full event surface. Use when building PreToolUse validation,
    PostToolUse formatting or redaction, PermissionRequest auto-approval, SessionStart context
    injection, Stop or SubagentStop continuation, PreCompact extraction, async guardrails,
    telemetry transmitters, a Codex hooks.json or config.toml adapter, or any deterministic
    blocking and non-blocking agent control — and when porting one canonical hook body across both
    providers. Where an instruction lives — memory, rule, setting, or hook — belongs to harness-config.
---

# [HOOKS_BUILDER]

A hook binds a handler — shell command, HTTP endpoint, MCP tool call, single-turn prompt, or multi-turn agent — to a lifecycle event, filtered by a matcher and an optional `if` rule. The event decides what the automation intercepts or observes, the handler decides whether the verdict is deterministic or judged, and the control channel decides how the verdict binds: exit 2 with a stderr reason is the one blocking primitive that behaves identically on both providers, and exit-0 stdout JSON is the scalpel that rewrites input, redacts output, or injects context. Build order: pick the event, pick the handler, write the config into the provider's settings surface, then prove it with a direct stdin replay before it ships.

## [01]-[ROUTING]

[REFERENCES]:

- [01]-[EVENTS](references/events.md): the full event census for both providers, per-event matcher values, input payload, exit-2 blockability, and decision-control fields; open when selecting an event or writing its input handling.
- [02]-[CONFIG](references/config.md): configuration placement and scopes, matcher-evaluation law, the five handler types with all fields, exec versus shell form, and the JSON output contract; open when wiring the settings entry.
- [03]-[DUAL_PROVIDER](references/dual-provider.md): the one-canonical-body plus thin-adapter pattern, the portable exit-2 path, the per-event output-dialect divergence, Codex discovery and trust, and the component-hook port; open when a hook must serve both Claude Code and Codex.
- [04]-[SCRIPTING](references/scripting.md): Python hook-script craft — uv single-file packaging, typed payload admission, the channel discipline, and the hot-path budget; open when writing a command-hook body.
- [05]-[INTEGRATION](references/integration.md): path placeholders, context injection, terminal notifications, env persistence, async execution, session-to-pane routing, the telemetry lane, and component-scoped frontmatter; open when the hook feeds context or runs off the hot path.
- [06]-[SECURITY](references/security.md): the security model — the threat surface, the enforcement-locus law, disposition by role, and supply-chain trust; open when reasoning about a hostile input or an untrusted hook.
- [07]-[VERIFICATION](references/verification.md): fixture replay, malformed-payload and timeout cases, the dual-mode red-team harness, the diagnostic surfaces, and the symptom index; open when proving a hook or diagnosing a misfire.

[TEMPLATES]:

- [01]-[PRETOOLUSE_GATE](templates/pretooluse-gate.py): typed PreToolUse validator, per-command semantic dispatch, sandbox admission, fail-closed exit-2 block.
- [02]-[POSTTOOLUSE_FORMAT](templates/posttooluse-format.py): MODE-polymorphic PostToolUse owner formatting through the `fmt` router and redacting tool output.
- [03]-[SESSION_CONTEXT](templates/session-context.py): SessionStart injector with gated probes, the session-to-pane routing capture, and env persistence.
- [04]-[STOP_CONTINUATION](templates/stop-continuation.py): Stop and SubagentStop evaluator with a durable counter, layered detection, and an error-aware reprompt.
- [05]-[ASYNC_GUARDRAIL](templates/async-guardrail.py): off-hot-path `asyncRewake` check that wakes the session only on findings new since the baseline.
- [06]-[PRECOMPACT_EXTRACT](templates/precompact-extract.py): PreCompact extractor writing a typed transcript summary as a handoff across the compaction boundary.
- [07]-[CODEX_ADAPTER](templates/codex-adapter.sh): thin per-provider adapter piping a Codex payload into one canonical body.

[EXAMPLES]:

- [01]-[FRAGMENTS](examples/fragments.md): advanced logic moves — command decomposition, the JSON scalpel, async rewake, completion-token continuation, the priority-banded registry, the loaded nudge artifact, telemetry chaining with the CloudEvents envelope, the dual-mode red-team harness, permission auto-approval, and durable state.

## [02]-[EVENT_SELECTION]

- Intercept before execution -> `PreToolUse` (block, rewrite input, or defer); permission dialogs -> `PermissionRequest`; after an auto-mode denial -> `PermissionDenied` (retry signal).
- React after completion -> `PostToolUse` (format, lint, redact output), `PostToolUseFailure` (error handling), `PostToolBatch` (after a parallel batch, before the next model call).
- Session boundaries -> `SessionStart` (context, watch paths, session title), `SessionEnd` (cleanup); one-time provisioning -> `Setup`.
- Per-prompt -> `UserPromptSubmit` (inject context or block); command expansion -> `UserPromptExpansion`; displayed text -> `MessageDisplay` (display-only rewrite).
- Completion judgment -> `Stop`/`SubagentStop` (prompt or agent handler, or a completion-token command hook).
- Teams and tasks -> `TeammateIdle` (keep working), `TaskCreated` (roll back), `TaskCompleted` (gate completion).
- Environment reactivity -> `FileChanged`, `CwdChanged`, `ConfigChange` (audit or block settings edits), `InstructionsLoaded` (observe memory loads); worktrees -> `WorktreeCreate`/`WorktreeRemove`; compaction -> `PreCompact`/`PostCompact`; MCP input -> `Elicitation`/`ElicitationResult`.
- Observation only -> `Notification`, `SubagentStart`, `StopFailure` (API-error autopsy; output and exit code ignored).

Codex carries ten of these events; the turn-done and team tiers are Claude-only. The delta and its fill are the events reference.

## [03]-[HANDLER_SELECTION]

| [INDEX] | [TYPE]     | [OWNS]                                             | [DEFAULT_TIMEOUT] |
| :-----: | :--------- | :------------------------------------------------- | :---------------: |
|  [01]   | `command`  | Deterministic validation, formatting, transforms   |       600s        |
|  [02]   | `http`     | POSTing event JSON to a service endpoint           |       600s        |
|  [03]   | `mcp_tool` | Calling a connected MCP server tool                |       600s        |
|  [04]   | `prompt`   | Single-turn LLM judgment, `{ok, reason}` decision  |        30s        |
|  [05]   | `agent`    | Multi-turn tool-using verification, up to 50 turns |        60s        |

`command` is the only handler both providers run and the only one that enforces hard security — an `mcp_tool` disconnect or a `prompt` model timeout degrades to a non-blocking error, so real policy rides `command`. Codex parses `prompt`/`agent`/`async` and skips them, and has no `http`/`mcp_tool` handler; a dual-provider hook is therefore a `command` hook. Prompt and agent handlers bind only to the judgment-eligible events; the eligibility roster is the config reference.

## [04]-[PROVIDER_DIVERGENCE]

Claude Code is the superset: thirty events, five handler types, `terminalSequence`, async, and a rich per-event JSON dialect. Codex is command-only, synchronous, ten events, tool coverage limited to `Bash`/`apply_patch`/MCP, with turn-complete living off the hook bus in `notify`. The one path that behaves identically on both is exit 2 plus a stderr reason on the shared tool and prompt events — a hook body that only ever blocks that way ports verbatim with zero dialect branching. The moment a hook blocks the Stop family on Codex, injects context, or rewrites a value through stdout JSON, the per-event dialect diverges and the dual-provider reference owns the exact shape per provider.

## [05]-[GATE]

A built hook proves before it ships: the settings JSON parses (`python3 -c "import json; json.load(open('.claude/settings.json'))"`), the script is executable, and a fixture replay exercises the handler — `printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"npm test"}}' | ./hook.py; echo $?` returns the intended exit code, with a malformed-payload replay proving the fail-closed path. The full verification battery, the dual-mode red-team harness, and the diagnostic surfaces are the verification reference.
