# [INTEGRATION]

Hooks reach beyond a single verdict through path placeholders, environment persistence, context injection, terminal notifications, background execution, session-to-pane routing, and component-scoped frontmatter.

## [01]-[PLACEHOLDERS_AND_ENV]

| [INDEX] | [SURFACE]               | [SCOPE]             | [VALUE]                                                      |
| :-----: | :---------------------- | :------------------ | :----------------------------------------------------------- |
|  [01]   | `${CLAUDE_PROJECT_DIR}` | All hooks           | Project root; also exported to stdio MCP servers             |
|  [02]   | `${CLAUDE_PLUGIN_ROOT}` | Plugin hooks        | Plugin installation directory; changes on each plugin update |
|  [03]   | `${CLAUDE_PLUGIN_DATA}` | Plugin hooks        | Persistent data directory surviving plugin updates           |
|  [04]   | `$CLAUDE_ENV_FILE`      | Session/file events | Path taking `export` lines that persist for the session      |
|  [05]   | `$CLAUDE_CODE_REMOTE`   | All hooks           | `"true"` in remote web environments, unset in the local CLI  |
|  [06]   | `$CLAUDE_EFFORT`        | All hooks           | Active effort level for the turn                             |

Placeholders substitute into `command` and each `args` element and export as environment variables on the spawned process either way. Exec form (`args` present) passes placeholders unquoted as single arguments; shell form wraps them in double quotes. Everything else — `session_id`, `tool_name`, `tool_input`, `cwd` — arrives as JSON on stdin, never as environment variables.

`SessionStart`, `Setup`, `CwdChanged`, and `FileChanged` can append `export` lines to `$CLAUDE_ENV_FILE` that persist into every later Bash call — the cache lane for an expensive one-time computation. That file is append-only and sourced in order, so a re-firing on resume supersedes a prior value. Every value written there passes `shlex.quote`: the file is sourced into bash, so an unquoted `$()` or backtick riding a branch name or fetched value executes on the next Bash call — the single most dangerous surface a `SessionStart` hook owns.

## [02]-[CONTEXT_INJECTION]

Exit-0 stdout lands as context the agent sees only on `UserPromptSubmit`, `UserPromptExpansion`, and `SessionStart`; elsewhere it goes to the debug log. `hookSpecificOutput.additionalContext` injects a system reminder on any event that carries it, placed by event: conversation start for `SessionStart`/`Setup`/`SubagentStart`, beside the prompt for `UserPromptSubmit`/`UserPromptExpansion`, beside the tool result for the tool events, and at turn end for `Stop`/`SubagentStop` (the conversation continues so the agent acts on the feedback).

- Values over 10,000 characters write to a session file and pass as a preview and the path; several hooks returning `additionalContext` on one event all deliver.
- Injected text reads as factual statements — "This repo uses `bun test`" — never as out-of-band system commands, which trip prompt-injection defenses and surface to the user instead of binding.
- Mid-session injections replay from the transcript on `--continue`/`--resume` rather than re-running, so timestamps and SHAs go stale; `SessionStart` re-runs on resume with `source: "resume"` and refreshes.
- Static conventions belong in CLAUDE.md, which loads without running a script; hooks inject only dynamic state — branch, deployment target, CI results, fetched external data.

`SessionStart` additionally accepts `initialUserMessage`, `watchPaths` (an array of absolute paths arming `FileChanged`; `CwdChanged` and `FileChanged` return the same field to replace the dynamic list), `sessionTitle`, and `reloadSkills`. Injection is cheapest when conditional — over-injecting on every prompt bloats context, so a nudge fires only when its condition triggers and phrases the miss as cheaply dismissible (the declarative nudge table is the nudge-injector example).

## [03]-[TERMINAL_SEQUENCES]

Hooks run without a controlling terminal — `/dev/tty` is unavailable — so desktop notifications, window titles, and bells return through the `terminalSequence` JSON field, which Claude Code emits on the hook's behalf. That allowlist is OSC `0`/`1`/`2` (titles), `9` (iTerm2/ConEmu/Windows Terminal/WezTerm, including `9;4` taskbar progress), `99` (Kitty), `777` (urxvt/Ghostty/Warp), and bare BEL; anything outside it — cursor moves, colors, OSC 8 hyperlinks, OSC 52 clipboard — rejects the whole field. Build the control bytes with `printf` octal escapes and the JSON with `jq -n --arg`:

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

`async: true` on a command hook runs it in the background while the agent continues; `asyncRewake: true` additionally wakes the session on exit 2 with stderr as a system reminder — the lane for long test suites, deployments, and external calls. Async hooks receive the same stdin, deliver `additionalContext` on the next turn (`systemMessage` goes to the user), and never block or decide — the triggering action already proceeded. Only command hooks run async; each firing is a separate process with no cross-firing deduplication, and completion notifications show under `--verbose` or `Ctrl+O`.

`asyncRewake` is never wired to `SessionStart`: the wake fires exit-2 stderr into the start of a fresh conversation, injecting a prior run's stale output as current context, so an `asyncRewake` body decodes `hook_event_name` and hard-returns 0 on `SessionStart` as defense-in-depth beside the wiring rule.

Its rewake wall is the 600s command-hook timeout; a scan that legitimately runs longer — a large-repo security sweep — forks rather than stretching the hook: the firing spawns a detached process writing its result to a session-keyed file and returns 0, and a later firing reads the completed file and wakes only on findings new since the last acknowledged set. This detached-harvest lane is also the dual-provider fallback: Codex parses `async` and skips it, so a portable guardrail runs synchronously or splits its slow leg to the same detached process.

## [05]-[SESSION_ROUTING]

No payload carries `tty` or `pid`, so a hook that routes a notification or telemetry row to a specific pane keys on `session_id` from stdin and derives terminal identity from its own runtime — the hook `command` is a child of the agent process and inherits its pane-env, while the tty answers only through the parent's process table: `ps -o tty= -p $PPID` for the tty, `$WEZTERM_PANE`/`$ZELLIJ_PANE_ID`/`$TMUX_PANE`/`$KITTY_WINDOW_ID`/`$TERM_SESSION_ID` for the pane.

A durable pattern captures the `session_id` ↔ `{tty, pane}` map at `SessionStart` into a JSON registry under XDG state and looks the pane up by `session_id` on later `Notification`/`Stop`; the session-context template carries the capture lane, and the statusline JSON carries the same `session_id` as a second correlation surface. A routing hook exits 0 on any failure so telemetry never blocks the harness, and the same session-keyed discipline governs any cross-session state a hook writes — a counter, a receipt, a file claim — so parallel sessions on one worktree never clobber each other.

## [06]-[COMPONENT_HOOKS]

Skills and subagents declare hooks in frontmatter with the same configuration shape, scoped to the component's lifetime and cleaned up when it finishes. Every event admits a component hook, and a subagent's `Stop` hooks convert automatically to `SubagentStop`. `once: true` — honored only in skill frontmatter — runs a hook a single time per session:

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

## [07]-[TELEMETRY]

A transmitter hook chains after the policy hook on the same event array, so the gate decides and the transmitter forwards without touching the verdict — wired `async: true`, its POST under a short timeout, exit 0 guaranteed unconditionally so a dead collector never gates the loop. Unconditional means one broad `except Exception` or a `finally` that exits 0, never a two-type `(DecodeError, HTTPError)` catch: `httpx.InvalidURL`, `CookieConflict`, and `StreamError` are not `HTTPError` subclasses, so a narrow catch lets a malformed sink URL escape as a non-zero exit.

CloudEvents `time` is a true-UTC RFC3339 stamp (`datetime.now(UTC)` or `gmtime`), never a local `strftime` with a `Z` suffix — that mislabels the offset and corrupts the estate's ISO-8601 UTC ledger.

Envelope shape is a two-tier policy. A private dashboard or registry takes the lightweight tier: the raw stdin payload nested whole, hot query keys (`tool_name`, `session_id`, `hook_event_name`, `agent_id`) hoisted flat beside it so the store indexes without a custom parser. A shared bus takes a CloudEvents 1.0 envelope — `specversion`, a reverse-DNS `type`, a `source` derived from `HOOK_PROVIDER` so a dual-provider fleet's events self-identify, an `id`, a `time`, and the raw payload in `data` with hook identity as flat lowercase extensions. Both tiers ride the telemetry-transmitter example.

Codex emits OTel natively through its `[otel]` exporter (`hooks.run`, `turn.token_usage`, `multi_agent.spawn`), so hook-level metrics duplicate it there — a Codex transmitter's value is the synchronous attention stream. A hook is invisible in the transcript unless it exits non-zero, so one that silently rewrites or blocks surfaces its intent through `systemMessage` and logs every firing to a file or transmitter, never stdout; observing a live hook is the verification reference.
