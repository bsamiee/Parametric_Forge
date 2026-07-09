# [HEADLESS]

Headless lanes run the agent loop without a terminal operator: `claude -p` for one-shot scripted calls, `--bg` for detached long-running sessions, the SDK packages for programmatic control. Lane choice is a determinism decision — how much ambient machine state the call is allowed to absorb.

## [01]-[PRINT_MODE]

`claude -p "<prompt>"` executes noninteractively with every CLI option available. There is no one at the permission prompt, so tool access is declared up front: `--allowedTools` grants, permission rules apply as configured, and piped stdin substitutes for Bash access when the input is already in hand. Structured output rides `--output-format`: `text`, `json` (result, session ID, metadata, `total_cost_usd` with a per-model breakdown for spend tracking), or `stream-json` for newline-delimited streaming. A background subagent or workflow started inside a `-p` run is awaited up to a ten-minute ceiling tunable through `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`; other background shells die five seconds after the final result.

## [02]-[BARE_MODE]

`--bare` skips discovery of hooks, skills, plugins, MCP servers, auto memory, and memory files — the same prompt then produces the same call on every machine, which is the CI requirement. Bash plus file read and edit tools remain; everything else is opt-in by flag: `--append-system-prompt` or `--append-system-prompt-file` for instructions, `--settings` for a settings payload, `--mcp-config` for servers, `--agents` for workers, `--plugin-dir` for a plugin. Bare mode reads no keychain, so authentication comes from `ANTHROPIC_API_KEY` or an `apiKeyHelper` inside the `--settings` payload. `--exclude-dynamic-system-prompt-sections` moves per-machine sections out of the system prompt so prompt-cache prefixes survive across hosts.

## [03]-[SESSIONS]

`--continue` reloads the most recent conversation in the working directory; `--resume <id>` targets one; `--fork-session` resumes under a fresh session ID so the original stays untouched — the branch operator for trying divergent continuations of one recorded session. Print-mode chains compose these: successive `-p` calls with `--continue` build a multi-step pipeline where each step inherits the accumulated conversation.

## [04]-[LAUNCH_AGENTS]

- [DYNAMIC]: `--agents '<json>'` defines subagents at launch with the same field names as frontmatter plus `prompt` — the lane for ephemeral worker definitions that never earn a file.
- [MOUNTED]: `--agent <name>` makes the named definition the main thread: its body replaces the harness system prompt, its `tools` and `model` bind the session, `initialPrompt` auto-submits, and `Agent(type, ...)` allowlists what it spawns. The `agent` setting persists the same choice per project.
- [BACKGROUND]: `--bg` starts a detached session and prints its ID; `claude agents` opens agent view over every live session — status, last response, input-needed signals, inline reply. `--exec` runs a shell command as a PTY-backed background job under the same management surface.

## [05]-[SDK]

The Agent SDK (Python and TypeScript) exposes the same loop, tools, permissions, hooks, subagents, and session model as the CLI with typed messages and approval callbacks. Worker definitions pass through the `agents` parameter and override same-name filesystem definitions; `Agent` in `allowedTools` auto-approves spawning. Worker activity is detectable as `Agent` tool-use blocks, and messages born inside a worker carry `parent_tool_use_id`. Resuming a worker takes both coordinates: `resume` with the session ID, the agent ID named in the prompt, and the same `agents` payload supplied again. The parent receives a worker's final message verbatim as the tool result and paraphrases it in its own reply unless instructed to pass it through. Workflow launches never prompt in `-p` or the SDK — runs start immediately under configured permission rules, so allowlists are the only gate.
