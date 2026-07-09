# [LIFECYCLE]

Events fall into three cadences: once per session (`SessionStart`, `SessionEnd`), once per turn (`UserPromptSubmit`, `Stop`, `StopFailure`), and per tool call inside the agentic loop (`PreToolUse`, `PostToolUse`). Everything else fires on its named occurrence. When an event fires and a matcher matches, the handler receives JSON context — stdin for command hooks, POST body for HTTP hooks — and optionally returns a decision.

## [01]-[EVENTS]

| [INDEX] | [EVENT]               | [FIRES]                                                                          |
| :-----: | :-------------------- | :------------------------------------------------------------------------------- |
|  [01]   | `SessionStart`        | Session begins or resumes                                                        |
|  [02]   | `Setup`               | `--init-only`, or `--init`/`--maintenance` in `-p` mode; one-time preparation    |
|  [03]   | `InstructionsLoaded`  | A CLAUDE.md or `.claude/rules/*.md` file loads into context, at start or lazily  |
|  [04]   | `UserPromptSubmit`    | A prompt is submitted, before Claude processes it                                |
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
|  [18]   | `Stop`                | Claude finishes responding                                                       |
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

## [02]-[MATCHER_VALUES]

Each event's matcher filters on a different input field; events absent from this table (`UserPromptSubmit`, `PostToolBatch`, `Stop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`, `MessageDisplay`, `CwdChanged`) take no matcher and always fire — a `matcher` field on them is silently ignored. The full `StopFailure` error-type roster: `rate_limit`, `overloaded`, `authentication_failed`, `oauth_org_not_allowed`, `billing_error`, `invalid_request`, `model_not_found`, `server_error`, `max_output_tokens`, `unknown`.

| [INDEX] | [EVENT]                                                                                                  | [FILTERS_ON]            | [VALUES]                                                                                                                                                                            |
| :-----: | :------------------------------------------------------------------------------------------------------- | :---------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  [01]   | Tool events (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`) | Tool name               | `Bash`, `Edit\|Write`, `mcp__.*`                                                                                                                                                    |
|  [02]   | `SessionStart`                                                                                           | How the session started | `startup`, `resume`, `clear`, `compact`                                                                                                                                             |
|  [03]   | `Setup`                                                                                                  | Triggering CLI flag     | `init`, `maintenance`                                                                                                                                                               |
|  [04]   | `SessionEnd`                                                                                             | Why the session ended   | `clear`, `resume`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other`                                                                                            |
|  [05]   | `Notification`                                                                                           | Notification type       | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`, `elicitation_complete`, `elicitation_response`, `agent_needs_input`, `agent_completed`                    |
|  [06]   | `SubagentStart` / `SubagentStop`                                                                         | Agent type              | `general-purpose`, `Explore`, `Plan`, custom names, plugin-scoped `^my-plugin:reviewer$`                                                                                            |
|  [07]   | `PreCompact` / `PostCompact`                                                                             | Compaction trigger      | `manual`, `auto`                                                                                                                                                                    |
|  [08]   | `ConfigChange`                                                                                           | Configuration source    | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`                                                                                                  |
|  [09]   | `FileChanged`                                                                                            | Watched filenames       | `.envrc\|.env` — literal names, `\|`-separated only                                                                                                                                 |
|  [10]   | `StopFailure`                                                                                            | Error type              | `rate_limit`, `overloaded`, `billing_error`, `server_error`, and peers |
|  [11]   | `InstructionsLoaded`                                                                                     | Load reason             | `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact`                                                                                                        |
|  [12]   | `UserPromptExpansion`                                                                                    | Command name            | Skill or command names                                                                                                                                                              |
|  [13]   | `Elicitation` / `ElicitationResult`                                                                      | MCP server name         | Configured MCP server names                                                                                                                                                         |

## [03]-[INPUT]

Every event delivers `session_id`, `prompt_id`, `transcript_path`, `cwd`, `hook_event_name`, and — on events that carry it — `permission_mode` (`default`, `plan`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`; the Manual mode arrives as `default`) and `effort` (`{level}` for the turn, also exported as `$CLAUDE_EFFORT`). Inside a subagent or under `--agent`, `agent_id` and `agent_type` ride along; a plugin-shipped subagent reports the plugin-scoped identifier. Tool events add `tool_name`, `tool_input`, and `tool_use_id`; `PostToolUse` adds `tool_response`; `PostToolUseFailure` adds `error` and optional `is_interrupt`; `Stop`/`SubagentStop` add `stop_hook_active` and `last_assistant_message` — the transcript file is written asynchronously and lags the turn, so the final assistant text reads from `last_assistant_message`, never the transcript. `UserPromptSubmit` carries `prompt`; `SessionStart` alone may carry `model`.

## [04]-[EXIT_CODES]

Exit 0 is success — stdout parses for JSON output, and on `UserPromptSubmit`, `UserPromptExpansion`, and `SessionStart` plain stdout lands as context Claude sees. Exit 2 is the blocking signal — stdout is ignored, stderr feeds back per the table. Any other exit code is a non-blocking error: the transcript shows a hook-error notice with the first stderr line and execution continues (exit 1 is non-blocking despite the Unix convention; policy enforcement uses exit 2). The exception is `WorktreeCreate`, where any non-zero exit aborts worktree creation.

| [INDEX] | [EVENT]                                                                  | [BLOCKS] | [EXIT_2_EFFECT]                                           |
| :-----: | :----------------------------------------------------------------------- | :------: | :-------------------------------------------------------- |
|  [01]   | `PreToolUse`                                                             |   Yes    | Blocks the tool call                                      |
|  [02]   | `PermissionRequest`                                                      |   Yes    | Denies the permission                                     |
|  [03]   | `UserPromptSubmit`                                                       |   Yes    | Blocks prompt processing and erases the prompt            |
|  [04]   | `UserPromptExpansion`                                                    |   Yes    | Blocks the expansion                                      |
|  [05]   | `Stop` / `SubagentStop`                                                  |   Yes    | Prevents stopping; the conversation continues             |
|  [06]   | `TeammateIdle`                                                           |   Yes    | Keeps the teammate working; stderr is its feedback        |
|  [07]   | `TaskCreated`                                                            |   Yes    | Rolls back the task creation                              |
|  [08]   | `TaskCompleted`                                                          |   Yes    | Prevents completion; stderr feeds back to the model       |
|  [09]   | `ConfigChange`                                                           |   Yes    | Blocks the change (except `policy_settings`)              |
|  [10]   | `PostToolBatch`                                                          |   Yes    | Stops the agentic loop before the next model call         |
|  [11]   | `PreCompact`                                                             |   Yes    | Blocks compaction                                         |
|  [12]   | `Elicitation`                                                            |   Yes    | Denies the elicitation                                    |
|  [13]   | `ElicitationResult`                                                      |   Yes    | Blocks the response; the action becomes decline           |
|  [14]   | `WorktreeCreate`                                                         |   Yes    | Any non-zero exit fails worktree creation                 |
|  [15]   | `PostToolUse` / `PostToolUseFailure`                                     |    No    | Shows stderr to Claude; the tool already ran or failed    |
|  [16]   | `PermissionDenied`                                                       |    No    | Ignored; only JSON `hookSpecificOutput.retry: true` acts  |
|  [17]   | `SessionStart` / `Setup` / `SubagentStart`                               |    No    | Hook-error notice in the transcript; the session proceeds |
|  [18]   | `Notification`, `SessionEnd`, `CwdChanged`, `FileChanged`, `PostCompact` |    No    | Stderr to user only                                       |
|  [19]   | `StopFailure`, `InstructionsLoaded`                                      |    No    | Output and exit code ignored                              |
|  [20]   | `MessageDisplay`                                                         |    No    | The original text displays                                |
|  [21]   | `WorktreeRemove`                                                         |    No    | Failures log in debug mode only                           |

## [05]-[DECISION_CONTROL]

JSON output on exit 0 gives finer control than exit codes; each event family reads a different decision surface.

| [INDEX] | [EVENTS]                                                                                                                                              | [PATTERN]               | [KEY_FIELDS]                                                                                                                                     |
| :-----: | :---------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------- |
|  [01]   | `UserPromptSubmit`, `UserPromptExpansion`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `Stop`, `SubagentStop`, `ConfigChange`, `PreCompact` | Top-level `decision`    | `decision: "block"`, `reason`; Stop/SubagentStop also take `hookSpecificOutput.additionalContext` for non-error feedback that continues the turn |
|  [02]   | `TeammateIdle`, `TaskCreated`, `TaskCompleted`                                                                                                        | Exit code or `continue` | Exit 2 blocks with stderr feedback; `{"continue": false, "stopReason"}` stops entirely                                                           |
|  [03]   | `PreToolUse`                                                                                                                                          | `hookSpecificOutput`    | `permissionDecision` (`allow`/`deny`/`ask`/`defer`), `permissionDecisionReason`                                                                  |
|  [04]   | `PermissionRequest`                                                                                                                                   | `hookSpecificOutput`    | `decision.behavior` (`allow`/`deny`), `decision.updatedInput`, `decision.updatedPermissions`, `decision.message`, `decision.interrupt`           |
|  [05]   | `PermissionDenied`                                                                                                                                    | `hookSpecificOutput`    | `retry: true` tells the model it may retry                                                                                                       |
|  [06]   | `WorktreeCreate`                                                                                                                                      | Path return             | Command hook prints the path on stdout; HTTP returns `hookSpecificOutput.worktreePath`                                                           |
|  [07]   | `Elicitation` / `ElicitationResult`                                                                                                                   | `hookSpecificOutput`    | `action` (`accept`/`decline`/`cancel`), `content` (form field values)                                                                            |
|  [08]   | `MessageDisplay`                                                                                                                                      | `hookSpecificOutput`    | `displayContent` replaces on-screen text; transcript and model view keep the original                                                            |
|  [09]   | `SessionStart`, `Setup`, `SubagentStart`                                                                                                              | Context only            | `additionalContext`; SessionStart also `initialUserMessage`, `watchPaths`, `sessionTitle`, `reloadSkills`                                        |
|  [10]   | `WorktreeRemove`, `Notification`, `SessionEnd`, `PostCompact`, `InstructionsLoaded`, `StopFailure`, `CwdChanged`, `FileChanged`                       | None                    | Side effects only — logging, cleanup                                                                                                             |

Three events rewrite content rather than only allow or block: `PreToolUse` `updatedInput` replaces tool arguments before the run, `PermissionRequest` `updatedInput` inside `decision`, and `PostToolUse` `updatedToolOutput` replaces the tool result. `UserPromptSubmit` never replaces the prompt — it only injects `additionalContext` alongside it. Redaction intercepts at `PreToolUse` for outbound inputs and `PostToolUse` for inbound results.
