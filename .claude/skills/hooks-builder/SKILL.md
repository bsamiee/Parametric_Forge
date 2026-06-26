---
name: hooks-builder
description: >-
  Creates Claude Code hooks executing shell commands, prompt evaluations, or multi-turn agents at 15 lifecycle events. Use when building PreToolUse validation, PostToolUse formatting, PermissionRequest auto-approval, Stop/SubagentStop evaluation, TeammateIdle prevention, TaskCompleted gating, Setup provisioning, SessionStart context injection, or deterministic agent control via blocking/non-blocking hooks.
---

# [H1][HOOKS-BUILDER]

Build Claude Code hooks—shell commands, prompt evaluations, or multi-turn agents execute at 15 agent lifecycle events.

**Tasks:**
1. Read [lifecycle.md](./references/lifecycle.md) — 14 events, input schemas, exit codes, blocking behavior
2. Read [schema.md](./references/schema.md) — Configuration structure, matchers, JSON responses, hook types
3. (integration) Read [integration.md](./references/integration.md) — Environment variables, context injection
4. (scripting) Read [scripting.md](./references/scripting.md) — Python standards, security patterns
5. (recipes) Read [recipes.md](./references/recipes.md) — Proven implementation patterns
6. (troubleshooting) Read [troubleshooting.md](./references/troubleshooting.md) — Known issues, platform workarounds
7. (prose) Apply `docs/standards` — Style, evidence, constraints
8. Validate — Quality gate; see §VALIDATION

**Scope:**
- *Event Selection:* Choose hook type by automation goal (blocking vs observing).
- *Configuration:* Author settings.json entries with matchers and timeouts.
- *Response Handling:* Control agent via exit codes, JSON responses, or prompt evaluation.

**References:**

| Domain          | File                                                |
| --------------- | --------------------------------------------------- |
| Schema          | [schema.md](references/schema.md)                   |
| Lifecycle       | [lifecycle.md](references/lifecycle.md)             |
| Integration     | [integration.md](references/integration.md)         |
| Scripting       | [scripting.md](references/scripting.md)             |
| Recipes         | [recipes.md](references/recipes.md)                 |
| Troubleshooting | [troubleshooting.md](references/troubleshooting.md) |
| Validation      | [validation.md](references/validation.md)           |

## [01]-[EVENT_SELECTION]

**Decision Gate:**
- *Intercept before execution?* → PreToolUse (validate/block/modify parameters)
- *Control permission dialogs?* → PermissionRequest (auto-approve/deny)
- *React after completion?* → PostToolUse (format, lint, add context)
- *React after failure?* → PostToolUseFailure (error handling, retry logic)
- *Inject at session boundaries?* → SessionStart (context), UserPromptSubmit (per-message)
- *One-time provisioning?* → Setup (tool installation, dependency setup via `claude --init`)
- *Evaluate task completion?* → Stop/SubagentStop (prompt/agent type for LLM judgment)
- *Coordinate teams?* → TeammateIdle (prevent idle), TaskCompleted (validate completion)
- *Observe subagent lifecycle?* → SubagentStart/SubagentStop (logging)

**Blocking Events (exit 2 blocks action):**

| [INDEX] | [EVENT]           | [EXIT_2_EFFECT]                                       |
| :-----: | ----------------- | ----------------------------------------------------- |
|  [01]   | PreToolUse        | Blocks tool call; stderr shown to Claude              |
|  [02]   | PermissionRequest | Denies the permission                                 |
|  [03]   | UserPromptSubmit  | Blocks prompt processing; erases prompt from context  |
|  [04]   | Stop              | Prevents Claude from stopping; continues conversation |
|  [05]   | SubagentStop      | Prevents subagent from stopping                       |
|  [06]   | TeammateIdle      | Prevents teammate from going idle; stderr = feedback  |
|  [07]   | TaskCompleted     | Prevents task completion; stderr = feedback to model  |

**Non-blocking Events (exit 2 shows stderr only):**

| [INDEX] | [EVENT]            | [EXIT_2_EFFECT]                              |
| :-----: | ------------------ | -------------------------------------------- |
|  [01]   | PostToolUse        | Shows stderr to Claude (tool already ran)    |
|  [02]   | PostToolUseFailure | Shows stderr to Claude (tool already failed) |
|  [03]   | SessionStart       | Shows stderr to user only                    |
|  [04]   | Setup              | Shows stderr to user only                    |
|  [06]   | SessionEnd         | Shows stderr to user only                    |
|  [07]   | Notification       | Shows stderr to user only                    |
|  [08]   | SubagentStart      | Shows stderr to user only                    |
|  [09]   | PreCompact         | Shows stderr to user only                    |

## [02]-[CONFIGURATION]

| [INDEX] | [SCOPE] | [PATH]                        | [USE]                | [GIT]  |
| :-----: | ------- | ----------------------------- | -------------------- | :----: |
|  [01]   | User    | `~/.claude/settings.json`     | Global, all projects |  N/A   |
|  [02]   | Project | `.claude/settings.json`       | Shared, committed    | Commit |
|  [03]   | Local   | `.claude/settings.local.json` | Personal, testing    | Ignore |

**Precedence:** Local > Project > User. Same-event hooks from all scopes run in parallel.

**Snapshot:** Hooks captured at startup; mid-session edits require `/hooks` review to reload.

## [03]-[IMPLEMENTATION]

| [INDEX] | [TYPE]  | [USE_CASE]                       | [TIMEOUT] | [CHARACTERISTICS]            |
| :-----: | ------- | -------------------------------- | :-------: | ---------------------------- |
|  [01]   | command | Validation, formatting, rules    |   600s    | Deterministic, shell scripts |
|  [02]   | prompt  | Complex evaluation, LLM judgment |    30s    | Single-turn, context-aware   |
|  [03]   | agent   | Tool-using evaluation            |    60s    | Multi-turn, up to 50 turns   |

**Prompt/Agent Eligible Events:** PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, UserPromptSubmit, Stop, SubagentStop, TaskCompleted.

[CRITICAL] TeammateIdle does NOT support prompt or agent hooks — exit codes only.

**Prompt/Agent Response Schema:**
```json
{"ok": true}
{"ok": false, "reason": "Explanation shown to Claude"}
```

`ok: true` allows the action. `ok: false` blocks it with the provided reason.

**Command Hook Fields:**

| [INDEX] | [FIELD]         | [TYPE]  |   [DEFAULT]   | [EFFECT]                                  |
| :-----: | --------------- | ------- | :-----------: | ----------------------------------------- |
|  [01]   | `type`          | string  |       —       | `"command"`, `"prompt"`, or `"agent"`     |
|  [02]   | `command`       | string  |       —       | Shell command or script path              |
|  [03]   | `timeout`       | number  | type-specific | Seconds: command=600, prompt=30, agent=60 |
|  [04]   | `async`         | boolean |    `false`    | Background execution; non-blocking        |
|  [05]   | `statusMessage` | string  |       —       | Custom spinner text during execution      |
|  [06]   | `once`          | boolean |    `false`    | Run once per session (skills only)        |

**Prompt/Agent Hook Fields:**

| [INDEX] | [FIELD]  | [TYPE] | [DEFAULT]  | [EFFECT]                                       |
| :-----: | -------- | ------ | :--------: | ---------------------------------------------- |
|  [01]   | `prompt` | string |     —      | Instructions for LLM; `$ARGUMENTS` = hook JSON |
|  [02]   | `model`  | string | fast model | Model to use for evaluation                    |

## [04]-[SCRIPTING]

Python 3.15+ with strict typing. Zero imperative patterns.

## [05]-[VALIDATION]

[VERIFY] Completion:
- [ ] Event: Selected correct hook type for automation goal.
- [ ] Blocking: Verified event supports blocking (7 events) or observing (8 events).
- [ ] Schema: Configuration structure validated per schema.md.
- [ ] Timeout: Correct units (seconds): command=600, prompt=30, agent=60.
- [ ] Integration: Environment variables and context injection applied.
- [ ] Scripting: Security patterns and tooling gates passed.
- [ ] Quality: JSON syntax valid, timeouts appropriate.

[REFERENCE] Operational checklist: [->validation.md](./references/validation.md)
