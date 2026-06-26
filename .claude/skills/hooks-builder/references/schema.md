# [H1][SCHEMA]

Three nesting levels: event -> matcher group -> hook handler.

## [01]-[STRUCTURE]

```json
{
  "hooks": {
    "EventName": [{
      "matcher": "ToolPattern",
      "hooks": [{ "type": "command", "command": "script-path", "timeout": 600 }]
    }]
  }
}
```

**Common fields (all types):** `type` (required: "command"|"prompt"|"agent"), `timeout` (command=600, prompt=30, agent=60), `statusMessage` (spinner text), `once` (boolean, skills only).
**Command fields:** `command` (shell command/path), `async` (background, no decision control).
**Prompt/Agent fields:** `prompt` (instructions, `$ARGUMENTS` = hook input JSON), `model` (fast model default).

## [02]-[MATCHERS]

**Tool matchers** (PreToolUse, PermissionRequest, PostToolUse, PostToolUseFailure):

| [INDEX] | [PATTERN]  | [EXAMPLE]           | [MATCHES]                    |
| :-----: | ---------- | ------------------- | ---------------------------- |
|  [01]   | Exact      | `"Bash"`            | Bash tool only               |
|  [02]   | Regex OR   | `"Edit\|Write"`     | Edit or Write                |
|  [03]   | Regex wild | `"Notebook.*"`      | NotebookRead, NotebookEdit   |
|  [04]   | Empty/`*`  | `""`                | All tools (catch-all)        |
|  [05]   | MCP        | `"mcp__memory__.*"` | All tools from memory server |

**Session matchers:** `"startup"`, `"resume"`, `"clear"`, `"compact"` (SessionStart); `"init"`, `"maintenance"` (Setup); `"clear"`, `"logout"`, `"prompt_input_exit"`, `"bypass_permissions_disabled"`, `"other"` (SessionEnd).
**Other matchers:** Notification: `"permission_prompt"`, `"idle_prompt"`, `"auth_success"`, `"elicitation_dialog"`. SubagentStart/Stop: agent type name. PreCompact: `"manual"|"auto"`.
**No matcher support:** UserPromptSubmit, Stop, TeammateIdle, TaskCompleted — always fire.

## [03]-[JSON_RESPONSES]

**Universal output (exit 0):** `continue` (false halts Claude), `stopReason` (message on halt), `suppressOutput` (hide stdout), `systemMessage` (warning to user).

**PreToolUse:** `hookSpecificOutput.permissionDecision` ("allow"|"deny"|"ask"), `permissionDecisionReason`, `updatedInput` (modify tool params), `additionalContext`.

**PermissionRequest:** `hookSpecificOutput.decision.behavior` ("allow"|"deny"), `decision.updatedInput`, `decision.updatedPermissions`, `decision.message` (deny reason), `decision.interrupt` (stop Claude on deny).

**Top-level decision** (UserPromptSubmit, PostToolUse, PostToolUseFailure, Stop, SubagentStop): `decision` ("block"), `reason`, `additionalContext`.

**Context injection** (SessionStart, Setup, UserPromptSubmit): Plain stdout or `additionalContext` in JSON. SessionStart supports `CLAUDE_ENV_FILE`. Setup stdout becomes context visible to Claude.

## [04]-[HOOK_TYPES]

**Command hooks:** Deterministic shell scripts. JSON stdin, exit codes + optional JSON stdout.
**Prompt hooks:** Single-turn LLM evaluation. Response: `{"ok": true}` or `{"ok": false, "reason": "..."}`.
**Agent hooks:** Multi-turn subagent with tool access (Read, Grep, Glob). Up to 50 turns. Same response schema as prompt.

**Eligible events (prompt/agent):** PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, UserPromptSubmit, Stop, SubagentStop, TaskCompleted.

[IMPORTANT] TeammateIdle does NOT support prompt or agent hooks — exit codes only.

## [05]-[TESTING]

| [INDEX] | [METHOD]    | [COMMAND]                                         |
| :-----: | ----------- | ------------------------------------------------- |
|  [01]   | List hooks  | `/hooks` interactive manager                      |
|  [02]   | Debug mode  | `claude --debug` — shows hook match/execution     |
|  [03]   | Verbose     | `Ctrl+O` toggle — shows hook output in transcript |
|  [04]   | Direct test | `echo '{"tool_name":"Bash"}' \| python hook.py`   |
|  [05]   | Disable all | `"disableAllHooks": true` in settings             |

[REFERENCE] Validation checklist: [->validation.md§01](./validation.md#01-schema_gate)
