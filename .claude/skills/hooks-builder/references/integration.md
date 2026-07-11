# [INTEGRATION]

Hooks reach beyond a single verdict through path placeholders, environment persistence, context injection, terminal notifications, background execution, session-to-pane routing, and component-scoped frontmatter.

## [01]-[PLACEHOLDERS_AND_ENV]

| [INDEX] | [SURFACE]               | [SCOPE]      | [VALUE]                                                      |
| :-----: | :---------------------- | :----------- | :----------------------------------------------------------- |
|  [01]   | `${CLAUDE_PROJECT_DIR}` | All hooks    | Project root; also exported to stdio MCP servers             |
|  [02]   | `${CLAUDE_PLUGIN_ROOT}` | Plugin hooks | Plugin installation directory; changes on each plugin update |
|  [03]   | `${CLAUDE_PLUGIN_DATA}` | Plugin hooks | Persistent data directory surviving plugin updates           |
|  [04]   | `$CLAUDE_ENV_FILE`      | SessionStart | Path taking `export` lines that persist for the session      |
|  [05]   | `$CLAUDE_CODE_REMOTE`   | All hooks    | `"true"` in remote web environments, unset in the local CLI  |
|  [06]   | `$CLAUDE_EFFORT`        | All hooks    | Active effort level for the turn                             |

Placeholders substitute into `command` and each `args` element and export as environment variables on the spawned process either way. Exec form (`args` present) passes placeholders unquoted as single arguments; shell form wraps them in double quotes. Everything else — `session_id`, `tool_name`, `tool_input`, `cwd` — arrives as JSON on stdin, never as environment variables. `SessionStart`, `Setup`, `CwdChanged`, and `FileChanged` can append `export` lines to `$CLAUDE_ENV_FILE` that persist into every later Bash call — the cache lane for an expensive one-time computation.

## [02]-[CONTEXT_INJECTION]

Exit-0 stdout lands as context the agent sees only on `UserPromptSubmit`, `UserPromptExpansion`, and `SessionStart`; elsewhere it goes to the debug log. `hookSpecificOutput.additionalContext` injects a system reminder on any event that carries it, placed by event: conversation start for `SessionStart`/`Setup`/`SubagentStart`, beside the prompt for `UserPromptSubmit`/`UserPromptExpansion`, beside the tool result for the tool events, and at turn end for `Stop`/`SubagentStop` (the conversation continues so the agent acts on the feedback).

- Values over 10,000 characters write to a session file and pass as a preview plus path; several hooks returning `additionalContext` on one event all deliver.
- The text reads as factual statements — "This repo uses `bun test`" — never as out-of-band system commands, which trip prompt-injection defenses and surface to the user instead of binding.
- Mid-session injections replay from the transcript on `--continue`/`--resume` rather than re-running, so timestamps and SHAs go stale; `SessionStart` re-runs on resume with `source: "resume"` and refreshes.
- Static conventions belong in CLAUDE.md, which loads without running a script; hooks inject only dynamic state — branch, deployment target, CI results, fetched external data.

`SessionStart` additionally accepts `initialUserMessage`, `watchPaths` (arming `FileChanged`), `sessionTitle`, and `reloadSkills`. Injection is cheapest when conditional — over-injecting on every prompt bloats context, so a nudge fires only when its condition triggers and phrases the miss as cheaply dismissible (the declarative nudge table is a fragments example).

## [03]-[TERMINAL_SEQUENCES]

Hooks run without a controlling terminal — `/dev/tty` is unavailable — so desktop notifications, window titles, and bells return through the `terminalSequence` JSON field, which Claude Code emits on the hook's behalf. The allowlist is OSC `0`/`1`/`2` (titles), `9` (iTerm2/ConEmu/Windows Terminal/WezTerm, including `9;4` taskbar progress), `99` (Kitty), `777` (urxvt/Ghostty/Warp), and bare BEL; anything outside it — cursor moves, colors, OSC 8 hyperlinks, OSC 52 clipboard — rejects the whole field. Build the control bytes with `printf` octal escapes and the JSON with `jq -n --arg`:

```bash accepted
#!/usr/bin/env bash
set -euo pipefail
input=$(cat)
body=$(jq -r '.message // "Needs your attention"' <<<"$input")
seq=$(printf '\033]777;notify;%s;%s\007' "Claude Code" "$body")
jq -nc --arg seq "$seq" '{terminalSequence: $seq}'
```

Codex has no `terminalSequence`; its terminal notifications ride `tui.notifications` (`agent-turn-complete`, `approval-requested`) with `tui.notification_method` = `auto`/`osc9`/`bel`, delegating delivery to the emulator.

## [04]-[ASYNC]

`async: true` on a command hook runs it in the background while the agent continues; `asyncRewake: true` additionally wakes the session on exit 2 with stderr as a system reminder — the lane for long test suites, deployments, and external calls. Async hooks receive the same stdin, deliver `additionalContext` on the next conversation turn (`systemMessage` goes to the user), and never block or decide, since the triggering action already proceeded. Only command hooks run async; each firing is a separate process with no cross-firing deduplication, and completion notifications show under `--verbose` or `Ctrl+O`. Codex parses `async` and skips it, so an async hook is Claude-only and a dual-provider guardrail runs synchronously or splits its slow leg to a detached process the body spawns itself.

## [05]-[SESSION_ROUTING]

No payload carries `tty` or `pid`, so a hook that routes a notification or a telemetry row back to a specific pane keys on `session_id` from stdin and derives terminal identity from its own runtime — the hook `command` is a child of the agent process and inherits its controlling TTY and pane-env. Read the tty from `ps -o tty= -p $$`, falling back to `$PPID`, and the pane from `$WEZTERM_PANE`/`$ZELLIJ_PANE_ID`/`$TMUX_PANE`/`$KITTY_WINDOW_ID`/`$TERM_SESSION_ID`. The durable pattern captures the `session_id` ↔ `{tty, pane}` map at `SessionStart` and looks the pane up by `session_id` on later `Notification`/`Stop`; the statusline JSON carries the same `session_id` as a second correlation surface. Any failure in a routing hook exits 0 so telemetry never blocks the harness.

## [06]-[COMPONENT_HOOKS]

Skills and subagents declare hooks in frontmatter with the same configuration shape, scoped to the component's lifetime and cleaned up when it finishes. Every event admits a component hook, and a subagent's `Stop` hooks convert automatically to `SubagentStop`. The `once: true` field — honored only in skill frontmatter — runs a hook a single time per session:

```yaml template
---
name: secure-operations
description: Perform operations with security checks
hooks:
    PreToolUse:
        - matcher: 'Bash'
          hooks:
              - type: command
                command: './scripts/security-check.py'
---
```

Plugin hooks live in `hooks/hooks.json` with an optional top-level `description` and merge with user and project hooks while the plugin is enabled.

## [07]-[OBSERVABILITY]

`/hooks` opens a read-only browser over every configured hook — event, matcher, type, full command or prompt, and source (`User`, `Project`, `Local`, `Plugin`, `Session`, `Built-in`); edits happen in the settings JSON, which the file watcher picks up. `claude --debug` traces matching and execution, and `Ctrl+O` verbose mode shows hook output in the transcript. Because a hook is invisible in the transcript unless it exits non-zero, a hook that silently rewrites or blocks is the hardest class to debug — surface intent through `systemMessage` and log every firing to a file or a transmitter. Removal is deletion from settings; `"disableAllHooks": true` suspends everything at its scope, and only managed-level `disableAllHooks` can suspend managed hooks.
