# [EVENTS]

Events fall into cadences: once per session (`SessionStart`, `SessionEnd`), once per turn (`UserPromptSubmit`, `Stop`, `StopFailure`), per tool call inside the agentic loop (`PreToolUse`, `PostToolUse`), and per named occurrence for everything else. When an event fires and a matcher matches, the handler receives JSON context — stdin for command hooks, POST body for HTTP hooks — and optionally returns a decision. The live configuration and its matcher values are browsable read-only through `/hooks`, and `claude --debug` prints the matched value for any firing.

## [01]-[EVENTS]

| [INDEX] | [EVENT]               | [FIRES]                                                                          |
| :-----: | :-------------------- | :------------------------------------------------------------------------------- |
|  [01]   | `SessionStart`        | Session begins or resumes                                                        |
|  [02]   | `Setup`               | `--init-only`, or `--init`/`--maintenance` in `-p` mode; one-time preparation    |
|  [03]   | `InstructionsLoaded`  | A CLAUDE.md or `.claude/rules/*.md` file loads into context, at start or lazily  |
|  [04]   | `UserPromptSubmit`    | A prompt is submitted, before the model processes it                             |
|  [05]   | `UserPromptExpansion` | A user-typed command expands into a prompt; the expansion is blockable           |
|  [06]   | `MessageDisplay`      | Assistant message text is displayed                                              |
|  [07]   | `PreToolUse`          | Before a tool call executes; blockable                                           |
|  [08]   | `PermissionRequest`   | A permission dialog appears                                                      |
|  [09]   | `PermissionDenied`    | The auto-mode classifier denies a tool call; `{retry: true}` permits a retry     |
|  [10]   | `PostToolUse`         | After a tool call succeeds                                                       |
|  [11]   | `PostToolUseFailure`  | After a tool call fails                                                          |
|  [12]   | `PostToolBatch`       | A full batch of parallel tool calls resolves, before the next model call         |
|  [13]   | `Notification`        | Claude Code sends a notification                                                 |
|  [14]   | `SubagentStart`       | A subagent is spawned                                                            |
|  [15]   | `SubagentStop`        | A subagent finishes                                                              |
|  [16]   | `TaskCreated`         | A task is being created via `TaskCreate`                                         |
|  [17]   | `TaskCompleted`       | A task is being marked completed                                                 |
|  [18]   | `Stop`                | The main agent finishes responding                                               |
|  [19]   | `StopFailure`         | The turn ends on an API error; output and exit code are ignored                  |
|  [20]   | `TeammateIdle`        | An agent-team teammate is about to go idle                                       |
|  [21]   | `ConfigChange`        | A configuration file changes during a session                                    |
|  [22]   | `CwdChanged`          | The working directory changes, for example on a `cd`                             |
|  [23]   | `FileChanged`         | A watched file changes on disk; the matcher names the filenames to watch         |
|  [24]   | `WorktreeCreate`      | A worktree is being created via `--worktree` or `isolation: "worktree"`          |
|  [25]   | `WorktreeRemove`      | A worktree is being removed, at session exit or when a subagent finishes         |
|  [26]   | `PreCompact`          | Before context compaction                                                        |
|  [27]   | `PostCompact`         | After context compaction completes                                               |
|  [28]   | `Elicitation`         | An MCP server requests user input during a tool call                             |
|  [29]   | `ElicitationResult`   | A user responds to an MCP elicitation, before the response returns to the server |
|  [30]   | `SessionEnd`          | The session terminates                                                           |

Codex fires ten of these — `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PermissionRequest`, `Stop`, `SubagentStart`, `SubagentStop`, `PreCompact`, `PostCompact` — and its tool events cover `Bash`, `apply_patch`, and MCP calls only, never `WebSearch` or other non-shell tools. Codex owns `Stop`/`SubagentStop` on the hook bus at turn scope, so a completion loop ports; the team and extra-lifecycle tier (`Notification`, `SessionEnd`, `PostToolUseFailure`, `PostToolBatch`, `Task*`, `TeammateIdle`, `Worktree*`, `Cwd`/`File`/`ConfigChange`, elicitation) is Claude-only, and Codex `notify` is a separate legacy notification channel beside the bus — not a turn-done hook — whose payload the dual-provider reference owns.

## [02]-[MATCHER_VALUES]

Each event's matcher filters on a different input field; a `matcher` on an event that takes none is silently ignored, and a new roster member the harness adds is matched by writing its value — the value set is what `/hooks` and `claude --debug` report live, never a frozen list. Events taking no matcher (always fire): `UserPromptSubmit`, `PostToolBatch`, `Stop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`, `MessageDisplay`, `CwdChanged`. Tool events are `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, and `PermissionDenied`.

| [INDEX] | [EVENT]                             | [FILTERS_ON]            | [REPRESENTATIVE_VALUES]                                  |
| :-----: | :---------------------------------- | :---------------------- | :------------------------------------------------------- |
|  [01]   | Tool events                         | Tool name               | `Bash`, `Edit\|Write`, `mcp__.*`                         |
|  [02]   | `SessionStart`                      | How the session started | `startup`, `resume`, `clear`, `compact`                  |
|  [03]   | `Setup`                             | Triggering CLI flag     | `init`, `maintenance`                                    |
|  [04]   | `SessionEnd`                        | Why the session ended   | `clear`, `resume`, `logout`, and peers                   |
|  [05]   | `Notification`                      | Notification type       | `permission_prompt`, `idle_prompt`, `agent_needs_input`  |
|  [06]   | `SubagentStart` / `SubagentStop`    | Agent type              | `general-purpose`, `Explore`, custom and plugin names    |
|  [07]   | `PreCompact` / `PostCompact`        | Compaction trigger      | `manual`, `auto`                                         |
|  [08]   | `ConfigChange`                      | Configuration source    | `user_settings`, `project_settings`, `skills`, and peers |
|  [09]   | `FileChanged`                       | Watched filenames       | `.envrc\|.env` — literal names, `\|`-separated only      |
|  [10]   | `StopFailure`                       | Error type              | `rate_limit`, `overloaded`, `billing_error`, and peers   |
|  [11]   | `InstructionsLoaded`                | Load reason             | `session_start`, `nested_traversal`, and peers           |
|  [12]   | `UserPromptExpansion`               | Command name            | Skill or command names                                   |
|  [13]   | `Elicitation` / `ElicitationResult` | MCP server name         | Configured MCP server names                              |

`FileChanged` and `StopFailure` use a narrower exact-match set — letters, digits, `_`, and `|` only; a hyphen, space, or comma there routes the matcher to the regex path, where only `|` separates alternatives. The matcher-character law that decides exact versus regex is the config reference.

## [03]-[INPUT]

Every event delivers `session_id`, `transcript_path`, `cwd`, `hook_event_name`, and — on events that carry it — `permission_mode` (`default`, `plan`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`) and `effort` (`{level}` for the turn, also exported as `$CLAUDE_EFFORT`). `prompt_id` is a per-turn UUID present once the first user input exists, so a `SessionStart` firing before any prompt carries none. Inside a subagent or under `--agent`, `agent_id` and `agent_type` ride along; a plugin-shipped subagent reports the plugin-scoped identifier. `agent_id` also rides the main agent under `--agent`, so it is not the main-versus-subagent discriminant — a `Stop`/`SubagentStop` handler discriminates on `hook_event_name` (`SubagentStop`) and `agent_type` against an explicit contract allowlist, never on the presence of `agent_id` or on a transcript-length guess, which misclassifies a substantive subagent as the main agent and livelocks it. Tool events add `tool_name`, `tool_input`, and `tool_use_id`; `PostToolUse` and `PostToolUseFailure` add `tool_response`; `Stop`/`SubagentStop` add `last_assistant_message` and `stop_hook_active` (`true` once a hook already forced continuation, capped at eight consecutive blocks, raised via `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`). The transcript file is written asynchronously and lags the turn, so the final assistant text reads from `last_assistant_message`, never the transcript. `UserPromptSubmit` carries `prompt`; `SessionStart` may carry `model`, `agent_type`, and `session_title`.

No payload on either provider carries `tty`, `pid`, `ppid`, or a terminal-pane id — a hook `command` runs as a child of the agent process and inherits its controlling TTY and pane-env, so pane identity is read from the hook's own runtime, never the payload. The session-to-pane routing pattern is the integration reference.

## [04]-[EXIT_CODES]

Exit 0 is success — stdout parses for JSON output, and on the context-landing events plain stdout reaches the agent directly (the placement law is the integration reference). Exit 2 is the blocking signal — stdout is ignored, stderr feeds back per the table. Any other exit code is a non-blocking error: the transcript shows a hook-error notice with the first stderr line and execution continues. Exit 1 is non-blocking despite the Unix convention, and treating it as a block is the field's most common failure; policy enforcement always exits 2. The exception is `WorktreeCreate`, where any non-zero exit aborts creation.

| [INDEX] | [EVENT]                                    | [BLOCKS] | [EXIT_2_EFFECT]                                           |
| :-----: | :----------------------------------------- | :------: | :-------------------------------------------------------- |
|  [01]   | `PreToolUse`                               |   Yes    | Blocks the tool call                                      |
|  [02]   | `PermissionRequest`                        |   Yes    | Denies the permission                                     |
|  [03]   | `UserPromptSubmit`                         |   Yes    | Blocks prompt processing and erases the prompt            |
|  [04]   | `UserPromptExpansion`                      |   Yes    | Blocks the expansion                                      |
|  [05]   | `Stop` / `SubagentStop`                    |   Yes    | Prevents stopping; the conversation continues             |
|  [06]   | `TeammateIdle`                             |   Yes    | Keeps the teammate working; stderr is its feedback        |
|  [07]   | `TaskCreated`                              |   Yes    | Rolls back the task creation                              |
|  [08]   | `TaskCompleted`                            |   Yes    | Prevents completion; stderr feeds back to the model       |
|  [09]   | `ConfigChange`                             |   Yes    | Blocks the change, except `policy_settings`               |
|  [10]   | `PostToolBatch`                            |   Yes    | Stops the agentic loop before the next model call         |
|  [11]   | `PreCompact`                               |   Yes    | Blocks compaction                                         |
|  [12]   | `Elicitation`                              |   Yes    | Denies the elicitation                                    |
|  [13]   | `ElicitationResult`                        |   Yes    | Blocks the response; the action becomes decline           |
|  [14]   | `WorktreeCreate`                           |   Yes    | Any non-zero exit fails worktree creation                 |
|  [15]   | `PostToolUse` / `PostToolUseFailure`       |    No    | Shows stderr to the model; the tool already ran or failed |
|  [16]   | `PermissionDenied`                         |    No    | Ignored; only JSON `hookSpecificOutput.retry: true` acts  |
|  [17]   | `SessionStart` / `Setup` / `SubagentStart` |    No    | Hook-error notice in the transcript; the session proceeds |
|  [18]   | Stderr-to-user events                      |    No    | Stderr to the user only                                   |
|  [19]   | `StopFailure` / `InstructionsLoaded`       |    No    | Output and exit code ignored                              |
|  [20]   | `MessageDisplay`                           |    No    | The original text displays                                |
|  [21]   | `WorktreeRemove`                           |    No    | Failures log in debug mode only                           |

Stderr-to-user events: `Notification`, `SessionEnd`, `PostCompact`, `CwdChanged`, `FileChanged`. On Codex the exit-2 block holds for `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, and the `Stop`/`SubagentStop` family alike — a script that only ever exits 2 with a stderr reason is the portable control path across both providers, and a Codex `Stop`/`SubagentStop` continuation reads that exit-2 stderr natively, with top-level `decision: "block"` JSON the equivalent stdout form.

## [05]-[DECISION_CONTROL]

JSON output on exit 0 gives finer control than exit codes; each event family reads a different decision surface, and choosing exit codes or JSON is exclusive — JSON is honored only on exit 0. Three events rewrite content rather than only allow or block: `PreToolUse` `updatedInput` replaces tool arguments before the run, `PermissionRequest` `updatedInput` inside `decision` does the same at the dialog, and `PostToolUse` `updatedToolOutput` replaces the tool result before the model reads it — so a rewrite intercepts outbound at `PreToolUse` and inbound at `PostToolUse`. Every rewrite field replaces the entire object it targets: `updatedInput` carries the full tool input with the changed key overridden, never the changed key alone. `UserPromptSubmit` never replaces the prompt; it only injects `additionalContext` alongside it. Outbound-secret redaction rides `PreToolUse` `updatedInput`; inbound redaction rides `PostToolUse` `updatedToolOutput`, which rewrites a built-in tool's output when the replacement matches the tool's output shape and is silently ignored on a mismatch — a bare `decision: "block"` leaves the original output in context and never redacts. The shape-preserving scrub is the scripting reference.

| [INDEX] | [EVENTS]                                         | [PATTERN]               | [KEY_FIELDS]                                          |
| :-----: | :----------------------------------------------- | :---------------------- | :---------------------------------------------------- |
|  [01]   | Top-level `decision` events                      | Top-level `decision`    | `decision: "block"`, `reason`                         |
|  [02]   | `TeammateIdle` / `TaskCreated` / `TaskCompleted` | Exit code or `continue` | `continue: false`, `stopReason`, or exit 2            |
|  [03]   | `PreToolUse`                                     | `hookSpecificOutput`    | `permissionDecision`, `permissionDecisionReason`      |
|  [04]   | `PermissionRequest`                              | `hookSpecificOutput`    | `decision.behavior`, and its rewrite peers            |
|  [05]   | `PermissionDenied`                               | `hookSpecificOutput`    | `retry: true` tells the model it may retry            |
|  [06]   | `WorktreeCreate`                                 | Path return             | stdout path; HTTP `hookSpecificOutput.worktreePath`   |
|  [07]   | `Elicitation` / `ElicitationResult`              | `hookSpecificOutput`    | `action` (`accept`/`decline`/`cancel`), `content`     |
|  [08]   | `MessageDisplay`                                 | `hookSpecificOutput`    | `displayContent` replaces on-screen text only         |
|  [09]   | `SessionStart` / `Setup` / `SubagentStart`       | Context only            | `additionalContext`, plus SessionStart context extras |
|  [10]   | Side-effect-only events                          | None                    | Side effects only — logging, cleanup                  |

- Top-level `decision` events: `UserPromptSubmit`, `UserPromptExpansion`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `Stop`, `SubagentStop`, `ConfigChange`, `PreCompact`.
- Side-effect-only events: `WorktreeRemove`, `Notification`, `SessionEnd`, `PostCompact`, `InstructionsLoaded`, `StopFailure`, `CwdChanged`, `FileChanged`.
- `PreToolUse` `permissionDecision` takes `allow`/`deny`/`ask`/`defer` and also carries `updatedInput`; `PermissionRequest` `decision` splits on `behavior` — the `allow` branch carries `updatedInput` and `updatedPermissions` (an array of `PermissionUpdate` entries — a `setMode` entry switching the session mode, or an `addRules` entry — `rules` of `{toolName, ruleContent?}` with `ruleContent` omitted for a whole-tool rule — whose `destination` (`session`, `localSettings`, `projectSettings`, or `userSettings`) writes a standing allow rule so a matched call never re-prompts), and the `deny` branch carries `message` and `interrupt`; SessionStart context adds `initialUserMessage`, `watchPaths`, `sessionTitle`, and `reloadSkills`.

`Stop` and `SubagentStop` also take `hookSpecificOutput.additionalContext` for non-error feedback that continues the turn without an error frame. Because `SessionStart` lands its context at the very start of a fresh conversation, an `asyncRewake` hook is never wired to it: the rewake's exit-2 stderr injects a prior run's stale output as current context — the leak the async lane in the integration reference owns and defends. Codex reads a narrower dialect on the same events, and its `PermissionRequest` fails closed on the rewrite fields Claude accepts — the per-provider divergence is the dual-provider reference.
