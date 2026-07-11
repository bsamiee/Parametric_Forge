# [DUAL_PROVIDER]

One hook body serves both Claude Code and Codex when the control channel is exit 2 plus a stderr reason — that path blocks identically on both, needs no dialect branching, and ports verbatim. Divergence begins the moment a hook injects context or rewrites a value through stdout JSON: the per-event output dialect differs, and a payload written for one provider no-ops on the other. The architecture that survives this is one canonical body plus a thin per-provider adapter — the body reads the shared stdin shape and decides, the adapter normalizes the dialect on the way out for the provider that needs it.

## [01]-[DIVERGENCE]

| [INDEX] | [AXIS]              | [CLAUDE_CODE]                                     | [CODEX]                                              |
| :-----: | :------------------ | :------------------------------------------------ | :-------------------------------------------------- |
|  [01]   | Events              | Thirty across the full lifecycle                  | Ten; no turn-done, team, task, or file tier         |
|  [02]   | Handlers            | `command`, `http`, `mcp_tool`, `prompt`, `agent`  | `command` only; others parse and skip               |
|  [03]   | Async               | `async` and `asyncRewake`                         | Parsed and skipped; every hook is synchronous       |
|  [04]   | Tool coverage       | Every tool                                        | `Bash`, `apply_patch`, and MCP calls only           |
|  [05]   | Turn-complete       | `Stop` and `Notification` on the hook bus         | Off-bus in `notify`; no turn-done hook              |
|  [06]   | Input transport     | One JSON object on stdin                          | One JSON object on stdin, `additionalProperties:false` |
|  [07]   | Terminal escape     | `terminalSequence` JSON field                     | None; notifications ride `tui.notifications`        |
|  [08]   | Per-turn key        | `prompt_id` (UUID)                                | `turn_id` (present on every event except `SessionStart`) |

The Codex stdin shape is a strict superset-safe overlay: `session_id`, `transcript_path`, `cwd`, `model`, `permission_mode`, and `hook_event_name` map name-for-name onto Claude's, and Codex adds `turn_id` additively — a body reading the shared fields ignores `turn_id` harmlessly, so the same stdin parse serves both. A subagent hook reuses the parent `session_id` on both providers, and `agent_id` presence is the main-versus-subagent discriminant on both.

## [02]-[OUTPUT_DIALECTS]

Codex runs two block dialects that are not interchangeable, and a generator must emit the exact one per event or the hook no-ops:

| [INDEX] | [CODEX_EVENT]                      | [DECISION_SURFACE]                                                        |
| :-----: | :--------------------------------- | :----------------------------------------------------------------------- |
|  [01]   | `SessionStart`                     | `hookSpecificOutput.additionalContext`                                   |
|  [02]   | `UserPromptSubmit`                 | `decision: "block"` + `reason`; `hookSpecificOutput.additionalContext`   |
|  [03]   | `PreToolUse`                       | `hookSpecificOutput.permissionDecision` (`allow`/`deny`/`ask`), `updatedInput`; or top-level `decision: "approve"/"block"` |
|  [04]   | `PostToolUse`                      | Top-level `decision: "block"`                                            |
|  [05]   | `PermissionRequest`                | `hookSpecificOutput.decision.behavior` (`allow`/`deny` only — no `ask`, no rewrite) |
|  [06]   | `Stop` / `SubagentStop`            | Top-level `decision: "block"` + `reason`                                 |

Codex `PermissionRequest` reserves `interrupt`, `updatedInput`, and `updatedPermissions` and fails closed if any is set, so the rewrite that Claude's `PermissionRequest` accepts is a Codex trap — rewrite at `PreToolUse` instead, which both providers honor. The common output envelope (`continue`, `stopReason`, `suppressOutput`, `systemMessage`) is identical on both.

## [03]-[CANONICAL_BODY_PLUS_ADAPTER]

The body is provider-agnostic: it reads stdin once into a typed payload, decides, and either exits 2 with a stderr reason or writes the exact JSON dialect for the event it targets. The adapter is a thin shell that pipes the provider's payload into that body and normalizes only what the exit-2 path cannot carry.

- [EXIT_2_PATH]: A body that only ever blocks via exit 2 needs no adapter — the same executable wires directly into both `settings.json` and `hooks.json`. This is the default for every gate and guardrail; reach for stdout JSON only when the hook must rewrite or inject.
- [STDOUT_PATH]: A body that injects context or rewrites emits Claude's dialect natively and the adapter rewrites it to Codex's dialect with `jq` — `permissionDecision:"deny"` becomes `decision.behavior:"deny"` at `PermissionRequest`, a Claude pass-through `{}` becomes an empty object, and a Claude-only event the body targets is dropped. The adapter never mutates stdin; the additive `turn_id` passes through untouched.
- [BRAND]: The adapter exports a provider brand (`HOOK_PROVIDER=codex`) so the one body can select its output dialect from an environment value rather than sniffing the payload. Matcher-level tool aliasing handles the `apply_patch`-versus-`Edit` name split; the body never remaps `tool_name`.

The codex-adapter template is the worked form; the fragments example shows the single-dispatcher body that routes every event through one entry point.

## [04]-[CODEX_PLACEMENT]

Codex hooks are enabled by default (disable with `[features].hooks = false`) and load from four roots plus enabled-plugin bundles: `~/.codex/hooks.json`, `~/.codex/config.toml`, `<repo>/.codex/hooks.json`, and `<repo>/.codex/config.toml`. Repo-scoped `.codex/` loads only for trusted projects, and a restart re-scans. The `hooks.json` shape is identical to Claude's `settings.json > hooks`; the inline TOML form is an array-of-tables with a nested `.hooks` sub-table:

```toml template
[[hooks.PreToolUse]]
matcher = "Bash|apply_patch"

[[hooks.PreToolUse.hooks]]
type = "command"
command = '/usr/bin/env python3 "$(git rev-parse --show-toplevel)/.codex/hooks/guard.py"'
timeout = 30
statusMessage = "Checking command"
```

Trust is recorded against the hook's SHA: a new or changed hook is marked for review and skipped until trusted through the `/hooks` browser; `--dangerously-bypass-hook-trust` runs enabled hooks once without persisting trust. Managed hooks (policy-trusted) cannot be user-disabled. `Bash|apply_patch` is the portable file-plus-shell matcher, since Codex's `apply_patch` is the tool Claude calls `Edit`/`Write`. Turn-complete has no hook — a dual-provider "turn done" signal rides Codex `notify = ["prog", "lane"]`, which spawns `prog` with one JSON argument (`{type, thread-id, turn-id, cwd, input-messages, last-assistant-message}`) at turn end, while everything else stays on the hook bus.

## [05]-[SKILL_PORT_CONTRACT]

A hook-building skill itself ships to both providers from one tree. Codex reads exactly two frontmatter keys — `name` (≤64 chars) and `description` (≤1024 chars, hard-truncated) — and ignores Claude-only keys (`disable-model-invocation`, `user-invocable`, `context: fork`, `allowed-tools`) as inert, so a single `SKILL.md` loads on both. The body, `references/`, `templates/`, and `examples/` port verbatim; Codex walks the same progressive-disclosure tree. The port target is `~/.agents/skills/<name>/` (legacy `~/.codex/skills/` still loads), and propagation is a copy that strips the Claude-only keys, never sync tooling. Codex invocation policy, when it must be restricted, moves out of frontmatter into `agents/openai.yaml` (`policy.allow_implicit_invocation: false`). Two same-name skills both list on Codex rather than shadowing, so a port must not leave a stale copy beside the new one.
