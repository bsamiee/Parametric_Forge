---
name: hooks-builder
description: >-
    Builds Claude Code and Codex hooks as one discipline — command, HTTP, MCP-tool, prompt, and
    agent handlers across the full event surface. Use when building PreToolUse validation,
    PostToolUse formatting or redaction, PermissionRequest auto-approval, SessionStart context
    injection, Stop or SubagentStop continuation, PreCompact extraction, async guardrails,
    telemetry transmitters, a Codex hooks.json or config.toml adapter, or any deterministic
    blocking and non-blocking agent control — and when porting one canonical hook body across both
    providers. Where an instruction lives — memory, rule, setting, or hook — belongs to harness-steering.
---

# [HOOKS_BUILDER]

A hook binds a handler — shell command, HTTP endpoint, MCP tool call, single-turn prompt, or multi-turn agent — to a lifecycle event, filtered by a matcher and an optional `if` rule. Event selection decides what the automation intercepts or observes, handler selection decides whether the verdict is deterministic or judged, and control-channel selection decides how the verdict binds: exit 2 with a stderr reason is the one blocking primitive that behaves identically on both providers, and exit-0 stdout JSON is the scalpel that rewrites input, redacts output, or injects context. Build order: pick the event, pick the handler, write the config into the provider's settings surface, then prove it with a direct stdin replay before it ships. A Python body draws its dependencies from the estate's admitted libraries assumed uv-resolvable — `msgspec` for wire admission, `anyio` for structured concurrency and subprocess, `httpx` for transport, `stamina` for retry — composing the shipped primitive at full depth rather than a hand-rolled naive reimplementation, `msgspec`-lean on the hot path and richer off it.

## [01]-[ROUTING]

[REFERENCES]:
- [01]-[EVENTS](references/events.md): censuses both providers' events — matcher values, input payload, exit-2 blockability, decision-control fields.
- [02]-[CONFIG](references/config.md): placement, scopes, matcher-evaluation law, handler types and fields, exec versus shell, JSON output contract.
- [03]-[DUAL_PROVIDER](references/dual-provider.md): carries one canonical body behind thin adapters, the portable exit-2 path, per-event output-dialect divergence, Codex discovery and trust, the component-hook port.
- [04]-[SCRIPTING](references/scripting.md): Python hook body: uv single-file packaging, typed payload admission, channel discipline, hot-path budget.
- [05]-[INTEGRATION](references/integration.md): path placeholders, context injection, terminal notifications, env persistence, async execution, session-to-pane routing, the telemetry lane, component-scoped frontmatter.
- [06]-[SECURITY](references/security.md): owns the threat surface, the enforcement-locus law, disposition by role, and supply-chain trust.
- [07]-[VERIFICATION](references/verification.md): fixture replay, malformed-payload and timeout cases, red-team harness, diagnostics, symptom index.
- [08]-[RECIPES](references/recipes.md): catalogs each advanced move — command decomposition, value rewrite, priority-banded dispatch, the completion loop, data-driven injection, hot-path offload, the telemetry chain, standing permission, durable state, the paired audit — with its hinge and the naive form it beats.

[TEMPLATES]:
- [01]-[PRETOOLUSE_GATE](templates/pretooluse-gate.py): typed validator, per-command semantic dispatch, sandbox admission, fail-closed exit-2 block.
- [02]-[POSTTOOLUSE_FORMAT](templates/posttooluse-format.py): MODE-polymorphic owner formatting through the `fmt` router, redacting tool output.
- [03]-[SESSION_CONTEXT](templates/session-context.py): SessionStart injector with gated probes, session-to-pane routing capture, and env persistence.
- [04]-[STOP_CONTINUATION](templates/stop-continuation.py): Stop/SubagentStop evaluator: durable counter, layered detection, error-aware reprompt.
- [05]-[ASYNC_GUARDRAIL](templates/async-guardrail.py): off-hot-path `asyncRewake` check waking the session only on findings new since the baseline.
- [06]-[PRECOMPACT_EXTRACT](templates/precompact-extract.py): writes a typed transcript summary as the handoff across the compaction boundary.
- [07]-[CODEX_ADAPTER](templates/codex-adapter.sh): thin per-provider adapter piping a Codex payload into one canonical body.

[EXAMPLES]: complete droppable exemplars, each composing several recipe moves into one production hook.
- [01]-[DISPATCH_DAEMON](examples/dispatch-daemon.py): priority-banded handler registry on a session-scoped Unix socket, in-process when none answers.
- [02]-[REDTEAM_HARNESS](examples/redteam-harness.py): paired-corpus auditor, subprocess or in-process; reports each fixture against its benign twin.
- [03]-[TELEMETRY_TRANSMITTER](examples/telemetry-transmitter.py): async CloudEvents or private-tier, chained after policy, fail-open by construction.
- [04]-[PERMISSION_AUTOAPPROVE](examples/permission-autoapprove.py): persists a durable PermissionRequest rule; codex brand strips reserved fields.
- [05]-[NUDGE_INJECTOR](examples/nudge-injector.py): UserPromptSubmit table decoded from `nudges.json` with match/exclude regex and a priority band.

## [02]-[EVENT_SELECTION]

- Intercept before execution -> `PreToolUse` (block, rewrite input, or defer).
- Permission dialogs -> `PermissionRequest`; after an auto-mode denial -> `PermissionDenied` (retry signal).
- React after completion -> `PostToolUse` (format, lint, redact output), `PostToolUseFailure` (error handling).
- After a parallel batch, before the next model call -> `PostToolBatch`.
- Session boundaries -> `SessionStart` (context, watch paths, session title), `SessionEnd` (cleanup); one-time provisioning -> `Setup`.
- Per-prompt -> `UserPromptSubmit` (inject context or block); command expansion -> `UserPromptExpansion`.
- Displayed text -> `MessageDisplay` (display-only rewrite).
- Completion judgment -> `Stop`/`SubagentStop` (prompt or agent handler, or a completion-token command hook).
- Teams and tasks -> `TeammateIdle` (keep working), `TaskCreated` (roll back), `TaskCompleted` (gate completion).
- Environment reactivity -> `FileChanged`, `CwdChanged`, `ConfigChange` (audit or block settings edits), `InstructionsLoaded` (observe memory loads).
- Worktrees -> `WorktreeCreate`/`WorktreeRemove`; compaction -> `PreCompact`/`PostCompact`; MCP input -> `Elicitation`/`ElicitationResult`.
- Observation only -> `Notification`, `SubagentStart`, `StopFailure` (API-error autopsy; output and exit code ignored).

Codex carries ten of these events, `Stop`/`SubagentStop` among them; the team and extra-lifecycle tiers are Claude-only. Its delta and fill are the events reference.

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

Claude Code is the superset: thirty events, five handler types, `terminalSequence`, async, and a rich per-event JSON dialect. Codex is command-only, synchronous, ten events including `Stop`/`SubagentStop`, tool coverage limited to `Bash`/`apply_patch`/MCP, with `notify` a separate legacy notification channel beside the bus. Exit 2 plus a stderr reason on the shared tool, prompt, and `Stop`/`SubagentStop` events is the one path that behaves identically on both — a hook body that only ever blocks that way ports verbatim with zero dialect branching. Once a hook injects context or rewrites a value through stdout JSON, the per-event dialect diverges and the dual-provider reference owns the exact shape per provider.

## [05]-[GATE]

A built hook proves before it ships: the settings JSON parses (`python3 -c "import json; json.load(open('.claude/settings.json'))"`), the script is executable, and a fixture replay exercises the handler — `printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"npm test"}}' | ./hook.py; echo $?` returns the intended exit code, with a malformed-payload replay proving the fail-closed path. Full verification battery, dual-mode red-team harness, and diagnostic surfaces are the verification reference.
