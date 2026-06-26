# [H1][LIFECYCLE]

Fifteen lifecycle events span agent execution. Each fires at distinct point with event-specific input.

## [01]-[EVENTS]

| [INDEX] | [EVENT]            | [TRIGGER]                        | [CAN_BLOCK] | [OUTPUT_VISIBILITY]   |
| :-----: | ------------------ | -------------------------------- | :---------: | --------------------- |
|  [01]   | SessionStart       | Session begins or resumes        |     No      | Context for Claude    |
|  [02]   | Setup              | `claude --init` or `--init-only` |     No      | Context for Claude    |
|  [03]   | UserPromptSubmit   | User submits prompt              |     Yes     | Context for Claude    |
|  [04]   | PreToolUse         | Before tool execution            |     Yes     | Verbose mode (Ctrl+O) |
|  [05]   | PermissionRequest  | Permission dialog about to show  |     Yes     | Verbose mode (Ctrl+O) |
|  [06]   | PostToolUse        | After tool succeeds              |     No      | Verbose mode (Ctrl+O) |
|  [07]   | PostToolUseFailure | After tool fails                 |     No      | Verbose mode (Ctrl+O) |
|  [08]   | Notification       | Agent sends notification         |     No      | User only             |
|  [09]   | SubagentStart      | Subagent spawned                 |     No      | User only             |
|  [10]   | SubagentStop       | Subagent finishes                |     Yes     | Verbose mode (Ctrl+O) |
|  [11]   | Stop               | Agent finishes responding        |     Yes     | Verbose mode (Ctrl+O) |
|  [12]   | TeammateIdle       | Teammate about to go idle        |     Yes     | Feedback to teammate  |
|  [13]   | TaskCompleted      | Task marked as completed         |     Yes     | Feedback to model     |
|  [14]   | PreCompact         | Before context compaction        |     No      | User only             |
|  [15]   | SessionEnd         | Session terminates               |     No      | User only             |

[CRITICAL] Exit code 2 blocks action for events marked `Yes` in CAN_BLOCK column. PostToolUse/PostToolUseFailure exit 2 shows stderr to Claude but cannot undo the tool call. Setup runs only on explicit `claude --init` or `claude --init-only` invocation — not on regular session start.

## [02]-[INPUT_SCHEMAS]

### [2.1]-[COMMON_FIELDS]

All events receive via stdin JSON:

| [INDEX] | [FIELD]           | [TYPE] | [DESCRIPTION]                                                    |
| :-----: | ----------------- | ------ | ---------------------------------------------------------------- |
|  [01]   | `session_id`      | string | Current session identifier                                       |
|  [02]   | `transcript_path` | string | Path to session transcript JSONL                                 |
|  [03]   | `hook_event_name` | string | Event name (e.g., "PreToolUse")                                  |
|  [04]   | `cwd`             | string | Current working directory                                        |
|  [05]   | `permission_mode` | string | `default`, `plan`, `acceptEdits`, `dontAsk`, `bypassPermissions` |

### [2.2]-[TOOL_EVENTS]

PreToolUse, PermissionRequest, PostToolUse, PostToolUseFailure add:

| [INDEX] | [FIELD]       | [TYPE] | [DESCRIPTION]                         |
| :-----: | ------------- | ------ | ------------------------------------- |
|  [01]   | `tool_name`   | string | Tool being invoked (matcher target)   |
|  [02]   | `tool_input`  | object | Tool parameters (tool-specific shape) |
|  [03]   | `tool_use_id` | string | Unique tool invocation ID             |

PostToolUse adds `tool_response` (object). PostToolUseFailure adds `error` (string) and optional `is_interrupt` (boolean).

### [2.3]-[STOP_EVENTS]

Stop and SubagentStop add:

| [INDEX] | [FIELD]            | [TYPE]  | [DESCRIPTION]                                    |
| :-----: | ------------------ | ------- | ------------------------------------------------ |
|  [01]   | `stop_hook_active` | boolean | True if a previous Stop hook kept Claude running |

SubagentStop additionally provides `agent_id` (string), `agent_type` (string), and `agent_transcript_path` (string).

### [2.4]-[SESSION_EVENTS]

| [INDEX] | [EVENT]      | [FIELD]  | [VALUES]                                                                       |
| :-----: | ------------ | -------- | ------------------------------------------------------------------------------ |
|  [01]   | SessionStart | `source` | `startup`, `resume`, `clear`, `compact`                                        |
|  [02]   | SessionStart | `model`  | Model identifier string                                                        |
|  [03]   | Setup        | `source` | `init`, `maintenance`                                                          |
|  [04]   | SessionEnd   | `reason` | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` |

### [2.5]-[SUBAGENT_EVENTS]

| [INDEX] | [EVENT]       | [FIELD]      | [DESCRIPTION]                      |
| :-----: | ------------- | ------------ | ---------------------------------- |
|  [01]   | SubagentStart | `agent_id`   | Unique identifier for the subagent |
|  [02]   | SubagentStart | `agent_type` | Agent name (matcher target)        |

### [2.6]-[TEAM_EVENTS]

| [INDEX] | [EVENT]       | [FIELD]            | [DESCRIPTION]                            |
| :-----: | ------------- | ------------------ | ---------------------------------------- |
|  [01]   | TeammateIdle  | `teammate_name`    | Name of teammate about to go idle        |
|  [02]   | TeammateIdle  | `team_name`        | Name of the team                         |
|  [03]   | TaskCompleted | `task_id`          | Identifier of task being completed       |
|  [04]   | TaskCompleted | `task_subject`     | Title of the task                        |
|  [05]   | TaskCompleted | `task_description` | Detailed description (may be absent)     |
|  [06]   | TaskCompleted | `teammate_name`    | Teammate completing task (may be absent) |
|  [07]   | TaskCompleted | `team_name`        | Team name (may be absent)                |

### [2.7]-[OTHER_EVENTS]

| [INDEX] | [EVENT]          | [FIELD]               | [DESCRIPTION]                                                            |
| :-----: | ---------------- | --------------------- | ------------------------------------------------------------------------ |
|  [01]   | UserPromptSubmit | `prompt`              | User's input text                                                        |
|  [02]   | PreCompact       | `trigger`             | `manual` or `auto`                                                       |
|  [03]   | PreCompact       | `custom_instructions` | Compaction instructions                                                  |
|  [04]   | Notification     | `message`             | Notification content                                                     |
|  [05]   | Notification     | `title`               | Optional notification title                                              |
|  [06]   | Notification     | `notification_type`   | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` |

## [03]-[EXIT_CODES]

| [INDEX] | [CODE] | [BEHAVIOR]                                              |
| :-----: | :----: | ------------------------------------------------------- |
|  [01]   |   0    | Success — stdout parsed for JSON; action proceeds       |
|  [02]   |   2    | Blocking error — stderr fed to Claude; action prevented |
|  [03]   | Other  | Non-blocking error — stderr shown in verbose mode only  |

[CRITICAL] Choose one approach per hook: exit codes alone, OR exit 0 with JSON for structured control. JSON is only processed on exit 0.

### [3.1]-[EXIT_2_BEHAVIOR]

| [INDEX] | [EVENT]             | [EXIT_2_EFFECT]                                        |
| :-----: | ------------------- | ------------------------------------------------------ |
|  [01]   | PreToolUse          | Blocks tool call; stderr shown to Claude               |
|  [02]   | PermissionRequest   | Denies the permission                                  |
|  [03]   | UserPromptSubmit    | Blocks prompt processing; erases prompt from context   |
|  [04]   | Stop                | Prevents Claude from stopping; continues conversation  |
|  [05]   | SubagentStop        | Prevents subagent from stopping                        |
|  [06]   | TeammateIdle        | Prevents teammate from going idle; stderr = feedback   |
|  [07]   | TaskCompleted       | Prevents task completion; stderr = feedback to model   |
|  [08]   | PostToolUse         | Shows stderr to Claude (tool already ran, cannot undo) |
|  [09]   | PostToolUseFailure  | Shows stderr to Claude (tool already failed)           |
|  [10]   | Non-blocking events | Shows stderr to user only (no effect on execution)     |

## [04]-[EXECUTION]

| [INDEX] | [PROPERTY]      | [VALUE]                                                              |
| :-----: | --------------- | -------------------------------------------------------------------- |
|  [01]   | Default timeout | 600s (command), 30s (prompt), 60s (agent)                            |
|  [02]   | Parallelization | All matching hooks run in parallel                                   |
|  [03]   | Deduplication   | Identical hook commands deduplicated                                 |
|  [04]   | Input           | JSON via stdin                                                       |
|  [05]   | Output          | stdout for JSON responses; stderr for errors                         |
|  [06]   | Environment     | `$CLAUDE_PROJECT_DIR`, `$CLAUDE_CODE_REMOTE`                         |
|  [07]   | Snapshot        | Hooks captured at startup; mid-session edits require `/hooks` review |

[REFERENCE] Validation checklist: [->validation.md§02](./validation.md#02-lifecycle_gate)
