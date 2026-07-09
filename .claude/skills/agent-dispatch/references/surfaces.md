# [SURFACES]

Every execution surface is a definition plus a runtime: the definition fixes what the worker knows and touches, the runtime fixes where it runs and how it reports. Power lives in the definition rows most operators never set.

## [01]-[SUBAGENT_DEFINITION]

A custom subagent is a Markdown file with YAML frontmatter whose body becomes the worker's entire system prompt — the worker never receives the full harness system prompt, only its own body plus environment details. Discovery priority: managed settings, `--agents` JSON, project `.claude/agents/` walking upward with nearest duplicate winning, user `~/.claude/agents/`, plugin `agents/`. Both watched directories hot-reload edits within seconds.

| [INDEX] | [FIELD]           | [EFFECT]                                                                                          |
| :-----: | :---------------- | :------------------------------------------------------------------------------------------------ |
|  [01]   | `tools`           | Allowlist; omit to inherit everything. `Agent` present lets the worker spawn nested subagents     |
|  [02]   | `disallowedTools` | Denylist applied before `tools` resolves against the remainder                                    |
|  [03]   | `model`           | `sonnet`, `opus`, `haiku`, `fable`, a full model ID, or `inherit` (the default)                   |
|  [04]   | `effort`          | Overrides session effort while the worker is active: `low` through `max`, model-dependent         |
|  [05]   | `permissionMode`  | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`                          |
|  [06]   | `maxTurns`        | Hard turn ceiling — the stall guard for unattended workers                                        |
|  [07]   | `skills`          | Full skill content injected at startup; unlisted skills stay invocable through the Skill tool     |
|  [08]   | `mcpServers`      | Inline server definitions scoped to this worker, or name references sharing the parent connection |
|  [09]   | `hooks`           | Lifecycle hooks active only while this worker runs; `Stop` converts to `SubagentStop`             |
|  [10]   | `memory`          | `user`, `project`, or `local` — a persistent directory surviving across sessions                  |
|  [11]   | `background`      | `true` forces background even when the parent wants the result immediately                        |
|  [12]   | `isolation`       | `worktree` runs the worker in a temporary git worktree branched from the default branch           |
|  [13]   | `initialPrompt`   | Auto-submitted first turn when the definition runs as the main session via `--agent`              |

## [02]-[MODEL_RESOLUTION]

Worker model resolves in fixed order: the `CLAUDE_CODE_SUBAGENT_MODEL` environment variable, the per-invocation `model` parameter, the frontmatter `model`, then the main conversation's model. Values excluded by an `availableModels` allowlist are skipped and the inherited model runs instead. Extended thinking follows the main conversation with no per-worker override.

## [03]-[TOOL_CONTROL]

- [PATTERNS]: `mcp__<server>` or `mcp__<server>__*` grants or removes a whole server; `mcp__*` on the deny side strips every MCP tool. A tool named in both lists is removed.
- [WITHHELD]: `AskUserQuestion`, `EnterPlanMode`, `ExitPlanMode` outside plan mode, `ScheduleWakeup`, and `WaitForMcpServers` never reach a subagent regardless of the `tools` list — workers cannot elicit, so prompts arrive decision-complete.
- [SPAWN_ALLOWLIST]: `Agent(worker, researcher)` in `tools` restricts spawnable types only for an agent running as the main thread via `claude --agent`; inside a subagent definition the type list is ignored and bare `Agent` grants nested spawning. Omitting `Agent` blocks spawning entirely.
- [PARENT_PRECEDENCE]: a parent in `bypassPermissions` or `acceptEdits` overrides the worker's `permissionMode`; a parent in auto mode forces auto on the worker and its frontmatter mode is ignored.

## [04]-[CONTEXT_SHIELDS]

- [PRELOAD]: `skills` injects full skill bodies at worker startup, removing discovery risk; the inverse is a skill with `context: fork`, where the skill picks the agent. Skills carrying `disable-model-invocation: true` refuse preloading.
- [SCOPED_MCP]: an MCP server defined inline in worker frontmatter keeps its tool descriptions out of the parent context entirely — the worker gets the tools, the parent pays nothing. The context-shield of choice for heavy servers used by one specialist.
- [MEMORY]: `memory: user` writes `~/.claude/agent-memory/<name>/`, `project` writes `.claude/agent-memory/<name>/` (versionable), `local` writes `.claude/agent-memory-local/<name>/`. The first 200 lines or 25KB of `MEMORY.md` load into the worker's system prompt, and Read, Write, and Edit are force-enabled for upkeep — the substrate for a warm specialist that accumulates domain knowledge instead of re-deriving it per spawn.
- [WORKTREE]: `isolation: worktree` gives the worker an isolated repository copy; commands whose working directory escapes the worktree fail rather than touching the main checkout, and a clean worktree is removed automatically.

## [05]-[FORKS]

A fork inherits the entire conversation — history, system prompt, tools, model — and reuses the parent's prompt cache, making it cheaper than a fresh subagent whenever the task needs the session's accumulated state. Tool calls stay out of the parent; only the final result returns. `/fork <directive>` launches one by hand; `CLAUDE_CODE_FORK_SUBAGENT=1` lets the model spawn the `fork` type itself and pushes every spawn to background. A fork spawns named subagents (counting toward depth) but never another fork, and it accepts `isolation: worktree` for edit safety.

## [06]-[BACKGROUND_RUNTIME]

Workers default to background; the foreground fires only when the result gates the parent's next step, and `background: true` pins a definition to background unconditionally. Ctrl+B backgrounds a running task; `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` forces everything synchronous and outranks fork mode. Background permission prompts surface in the main session naming the requesting worker — approve to release one call, Esc to deny that call while the worker lives on. An API error ends a background worker as failed with its last output attached; a foreground worker cut off mid-output returns the partial result flagged as unfinished. Retry or resume once the error clears.

## [07]-[RESUME]

Every completed worker returns an agent ID; Explore and Plan are one-shot and return none. `SendMessage` with the ID or name resumes the worker with full history — a stopped worker auto-resumes in background on receipt. Name targeting is guarded: when a name has been reassigned to a newer agent, delivery is refused and the error names the current holder, so the ID is the durable address. Transcripts live at `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`, survive parent compaction, persist across session resume, and expire under `cleanupPeriodDays`. Workers compact themselves under the same rules as the main conversation. No agent message ever satisfies a permission prompt or alters permissions, memory files, or configuration.

## [08]-[TEAMS]

Teams are gated behind `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`: one lead session plus full peer sessions with independent context windows, a shared task list, and direct peer messaging — mesh where subagents are hub-and-spoke. The first teammate spawn forms the team; cleanup rides session exit.

- [TASKS]: states are pending, in progress, completed, with dependencies; the lead assigns or teammates self-claim unblocked work under file locking. Plan-approval mode routes each teammate's plan to the lead before edits.
- [GATES]: exit code 2 from a `TeammateIdle` hook keeps a teammate working, from `TaskCreated` blocks the task, from `TaskCompleted` refuses completion — deterministic quality gates the lead never has to police.
- [CONTEXT]: a teammate receives its spawn prompt and project context, never the lead's conversation history; broadcast is one message per recipient; teammate messages carry no permission authority.
- [LIMITS]: one team per session, no nested teams, in-process teammates do not survive `/resume`; sizing sweet spot is three to five teammates owning disjoint files, five or six tasks each.

## [09]-[WORKFLOWS]

A workflow is a script the runtime executes outside the conversation: intermediates live in script variables, the session stays free, and only the final report lands in context. Caps: sixteen concurrent agents, a thousand per run, no mid-run user input, no direct filesystem or shell access from the script — agents do the work. Workflow subagents always run `acceptEdits` and inherit the session's tool allowlist regardless of permission mode, so long runs pre-approve the shell commands their agents need. Progress lives in `/workflows` (pause, stop, restart, per-agent tokens); a run projecting past twenty-five agents or one and a half million tokens raises an advisory warning. Saved runs become commands under `.claude/workflows/` (nearest directory wins in a monorepo, project beats personal) and read invocation input as a structured `args` global. Runs resume within the session from cached agent results; a fresh session starts the workflow over. The `ultracode` keyword opts one prompt in; `/effort ultracode` makes the model plan workflows for every substantive task.
