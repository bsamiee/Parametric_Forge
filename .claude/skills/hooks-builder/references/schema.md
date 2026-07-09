# [SCHEMA]

Configuration nests three levels: a hook event, a matcher group filtering when it fires, and one or more hook handlers that run when matched. All matching handlers run in parallel; identical handlers deduplicate automatically — command hooks by command string plus `args`, HTTP hooks by URL.

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{ "type": "command", "if": "Bash(rm *)", "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.sh", "args": [] }]
    }]
  }
}
```

## [01]-[LOCATIONS]

| [INDEX] | [LOCATION]                    | [SCOPE]                       | [SHAREABLE]                   |
| :-----: | :---------------------------- | :---------------------------- | :---------------------------- |
|  [01]   | `~/.claude/settings.json`     | All projects on the machine   | No                            |
|  [02]   | `.claude/settings.json`       | Single project                | Yes, committed                |
|  [03]   | `.claude/settings.local.json` | Single project, personal      | No, gitignored                |
|  [04]   | Managed policy settings       | Organization-wide             | Admin-controlled              |
|  [05]   | Plugin `hooks/hooks.json`     | While the plugin is enabled   | Bundled with the plugin       |
|  [06]   | Skill or agent frontmatter    | While the component is active | Defined in the component file |

Same-event hooks from all scopes run in parallel. Direct edits to settings hooks are picked up by the file watcher; `disableAllHooks: true` turns everything off temporarily, subject to the managed-settings hierarchy, and `allowManagedHooksOnly` lets administrators block user, project, and plugin hooks.

## [02]-[MATCHER_LAW]

Matcher evaluation depends on the characters it contains:

- [ALL]: `"*"`, `""`, or an omitted matcher fires on every occurrence of the event.
- [EXACT]: Only letters, digits, `_`, `-`, spaces, `,`, and `|` — an exact string or a `|`/`,`-separated list of exact strings: `Bash`, `Edit|Write`, `code-reviewer`.
- [REGEX]: Any other character routes to an unanchored JavaScript regular expression tested with `RegExp.prototype.test`: `^Notebook`, `mcp__memory__.*`. `Edit.*` matches both `Edit` and `NotebookEdit`; whole-string matches anchor as `^Edit$`.

`FileChanged` and `StopFailure` use a narrower exact-match set of letters, digits, `_`, and `|` only — a hyphen, space, or comma there keeps the matcher on the regex path, and only `|` separates alternatives.

MCP tools match as regular tools on tool events under the `mcp__<server>__<tool>` pattern. Matching every tool from a server requires the `.*` suffix — `mcp__memory__.*` — because a bare `mcp__memory` is exact-match and matches no tool. Plugin-bundled servers scope as `mcp__plugin_<plugin>_<server>__<tool>`; matchers written against the bare server key never fire for them.

The `if` field narrows further with exactly one permission rule — `"Bash(git *)"`, `"Edit(*.ts)"` — evaluated only on tool events; there is no `&&`/`||`, so multiple conditions become multiple handlers. Bash patterns strip leading `VAR=value` assignments, check each subcommand of `&&` chains, and check inside `$()` and backticks; patterns specifying more than the command name run the hook anyway on substitutions, and an unparseable command fails open. The `if` filter is best-effort — hard allow/deny enforcement belongs to the permission system, not a hook.

## [03]-[COMMON_FIELDS]

| [INDEX] | [FIELD]         | [EFFECT]                                                                                                                                                                  |
| :-----: | :-------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|  [01]   | `type`          | `"command"`, `"http"`, `"mcp_tool"`, `"prompt"`, or `"agent"`                                                                                                             |
|  [02]   | `if`            | Permission-rule filter on tool events; on other events a hook with `if` never runs                                                                                        |
|  [03]   | `timeout`       | Seconds before cancel — 600 for command/http/mcp_tool, 30 for prompt, 60 for agent      |
|  [04]   | `statusMessage` | Custom spinner text while the hook runs                                                                                                                                   |
|  [05]   | `once`          | Runs once per session then is removed; honored only in skill frontmatter                                                                                                  |

`UserPromptSubmit` lowers the command-family default timeout to 30 seconds and `MessageDisplay` lowers it to 10.

## [04]-[COMMAND_HOOKS]

Command hooks add `command`, `args`, `async`, `asyncRewake`, and `shell`. The form is chosen by `args`:

- [EXEC]: With `args`, `command` resolves as an executable and spawns directly with `args` as the argument vector — no shell, no tokenization, path placeholders substitute as plain strings. The form for any hook referencing a path placeholder.
- [SHELL]: Without `args`, the string passes to a shell (`sh -c` on macOS/Linux; Git Bash on Windows, PowerShell fallback, or `shell: "powershell"` explicitly) with full tokenization, pipes, and globs; placeholders wrap in double quotes.

On Windows, exec form requires a real executable — `.cmd`/`.bat` shims from `node_modules/.bin` spawn via `node` plus the script path instead. `async: true` runs the hook in the background without blocking (command hooks only); `asyncRewake: true` additionally wakes Claude on exit 2. Async hooks never block or return decisions — the action already proceeded; their `additionalContext` delivers on the next turn.

## [05]-[HTTP_AND_MCP_HOOKS]

HTTP hooks take `url`, optional `headers` (env-var interpolation only for names listed in `allowedEnvVars`), and receive the event JSON as the POST body. Status codes never block: non-2xx, connection failure, and timeout are all non-blocking errors; blocking requires a 2xx response whose JSON body carries the decision fields. MCP tool hooks take `server` (the configured server name, or `plugin:<plugin>:<server>` for plugin-bundled servers), `tool`, and optional `input` with `${path}` substitution from the hook input (`"${tool_input.file_path}"`); the tool's text output is treated like command stdout, a disconnected server or `isError: true` is a non-blocking error, and `SessionStart`/`Setup` typically fire before servers connect.

## [06]-[PROMPT_AND_AGENT_HOOKS]

Prompt hooks send `prompt` (with `$ARGUMENTS` standing for the hook input JSON; absent placeholder appends the JSON) to a fast model, overridable via `model`; the response schema is `{"ok": true}` or `{"ok": false, "reason": "..."}`. Agent hooks are the same configuration with tool access (Read, Grep, Glob) across up to 50 turns. `continueOnBlock: true` on a prompt hook feeds the block reason back to Claude and continues the turn where the event's default ends it.

On `ok: false`: `Stop`/`SubagentStop` feed the reason back as the next instruction; `PreToolUse` denies the call with the reason as the tool error; `PostToolUseFailure`, `TaskCreated`, and `TaskCompleted` return the reason as a tool error; `PostToolUse` ends the turn with a warning unless `continueOnBlock`; `PostToolBatch`, `UserPromptSubmit`, and `UserPromptExpansion` end the turn regardless; `TeammateIdle` stops the teammate unless `continueOnBlock`; `PermissionRequest` and `PermissionDenied` ignore `ok: false` — those two decide only through command-hook JSON.

Events taking all five handler types: `PermissionDenied`, `PermissionRequest`, `PostToolBatch`, `PostToolUse`, `PostToolUseFailure`, `PreToolUse`, `Stop`, `SubagentStop`, `TaskCompleted`, `TaskCreated`, `TeammateIdle`, `UserPromptExpansion`, `UserPromptSubmit`. Every other event takes `command`, `http`, and `mcp_tool` only, except `SessionStart` and `Setup`, which take `command` and `mcp_tool`.

## [07]-[JSON_OUTPUT]

JSON output is processed only on exit 0, and stdout must contain only the JSON object; one approach per hook — exit codes alone, or exit 0 with JSON. Output strings cap at 10,000 characters; overflow saves to a file and passes a preview plus path.

| [INDEX] | [FIELD]            | [EFFECT]                                                                             |
| :-----: | :----------------- | :----------------------------------------------------------------------------------- |
|  [01]   | `continue`         | `false` stops Claude entirely after the hook, over any event-specific decision       |
|  [02]   | `stopReason`       | Message shown to the user when `continue` is `false`; not shown to Claude            |
|  [03]   | `suppressOutput`   | `true` hides hook stdout from the transcript                                         |
|  [04]   | `systemMessage`    | Warning message shown to the user                                                    |
|  [05]   | `terminalSequence` | Allowlisted terminal escape emitted on the hook's behalf — notification, title, bell |

Per-event decision fields — top-level `decision`, `hookSpecificOutput` shapes, and the rewrite surfaces (`updatedInput`, `updatedToolOutput`, `displayContent`, `worktreePath`) — are the lifecycle reference's decision-control table.
