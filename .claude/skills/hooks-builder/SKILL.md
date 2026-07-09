---
name: hooks-builder
description: >-
  Creates Claude Code hooks — shell command, HTTP, MCP tool, prompt, and agent handlers
  firing across the full lifecycle event surface, from session and prompt events through
  tool, permission, task, teammate, worktree, compaction, and MCP elicitation events. Use
  when building PreToolUse validation, PostToolUse formatting, PermissionRequest
  auto-approval, Stop/SubagentStop evaluation, TeammateIdle or TaskCompleted gating,
  FileChanged or CwdChanged watchers, SessionStart context injection, Setup provisioning,
  config-change auditing, async background hooks, or any deterministic agent control via
  blocking and non-blocking hooks. Where an instruction lives — memory, rule, setting, or
  hook — belongs to harness-config.
---

# [HOOKS_BUILDER]

A hook binds a handler — shell command, HTTP endpoint, MCP tool call, single-turn prompt, or multi-turn agent — to a lifecycle event, filtered by a matcher and an optional `if` rule. Build order: pick the event by what the automation must intercept or observe, pick the handler type by whether the decision is deterministic or judged, then write the config and prove it with a direct stdin test.

- [01]-[LIFECYCLE]: [references/lifecycle.md](references/lifecycle.md) — the full event census, per-event matcher values, exit-2 blockability, and decision-control fields; open when selecting an event or writing its input handling.
- [02]-[SCHEMA]: [references/schema.md](references/schema.md) — configuration structure, matcher evaluation law, the five handler types with all fields, exec versus shell form, and JSON output; open when authoring the settings entry.
- [03]-[INTEGRATION]: [references/integration.md](references/integration.md) — path placeholders, context injection routing, terminal notifications, env persistence, async execution, and hooks in skill or agent frontmatter; open when the hook feeds context or runs in the background.
- [04]-[SCRIPTING]: [references/scripting.md](references/scripting.md) — Python hook-script standards; open when writing a command-hook script.
- [05]-[RECIPES]: [references/recipes.md](references/recipes.md) — proven implementations from security gate to stop evaluator; open for a working seed to adapt.
- [06]-[TROUBLESHOOTING]: [references/troubleshooting.md](references/troubleshooting.md) — platform behavior and misconfiguration symptoms; open when a hook misfires.

## [01]-[EVENT_SELECTION]

- Intercept before execution -> `PreToolUse` (block, rewrite input, or defer); permission dialogs -> `PermissionRequest`; after an auto-mode denial -> `PermissionDenied` (retry signal).
- React after completion -> `PostToolUse` (format, lint, rewrite output), `PostToolUseFailure` (error handling), `PostToolBatch` (after a parallel batch, before the next model call).
- Session boundaries -> `SessionStart` (context, watch paths, session title), `SessionEnd` (cleanup); one-time provisioning -> `Setup` (`--init-only`, or `--init`/`--maintenance` in `-p` mode).
- Per-prompt -> `UserPromptSubmit` (inject context or block); command expansion -> `UserPromptExpansion`; displayed text -> `MessageDisplay` (display-only rewrite).
- Completion judgment -> `Stop`/`SubagentStop` (prompt or agent handler); API-error turn end -> `StopFailure` (observe only).
- Teams and tasks -> `TeammateIdle` (keep working), `TaskCreated` (roll back creation), `TaskCompleted` (gate completion).
- Environment reactivity -> `FileChanged` (watched filenames), `CwdChanged` (direnv-style reaction), `ConfigChange` (audit or block settings edits), `InstructionsLoaded` (observe memory loads).
- Worktrees -> `WorktreeCreate` (replace git default, return the path), `WorktreeRemove`; compaction -> `PreCompact` (block or archive), `PostCompact`; MCP user input -> `Elicitation`/`ElicitationResult`.
- Observation only -> `Notification`, `SubagentStart`, `MessageDisplay`.

## [02]-[HANDLER_SELECTION]

| [INDEX] | [TYPE]     | [OWNS]                                             | [DEFAULT_TIMEOUT] |
| :-----: | :--------- | :------------------------------------------------- | :---------------: |
|  [01]   | `command`  | Deterministic validation, formatting, transforms   |       600s        |
|  [02]   | `http`     | POSTing event JSON to a service endpoint           |       600s        |
|  [03]   | `mcp_tool` | Calling a connected MCP server tool                |       600s        |
|  [04]   | `prompt`   | Single-turn LLM judgment, `{ok, reason}` decision  |        30s        |
|  [05]   | `agent`    | Multi-turn tool-using verification, up to 50 turns |        60s        |

Prompt and agent handlers bind only to the judgment-eligible events; `SessionStart` and `Setup` take `command` and `mcp_tool` only — the eligibility roster is in [references/schema.md](references/schema.md).

## [03]-[GATE]

A built hook proves before it ships: `python3 -c "import json; json.load(open('.claude/settings.json'))"` passes, and a direct stdin test exercises the handler — `printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' | ./hook.sh; echo $?` returns the intended exit code. `/hooks` browses the live configuration read-only; `claude --debug` traces match and execution.
