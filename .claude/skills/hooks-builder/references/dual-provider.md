# [DUAL_PROVIDER]

One hook body serves both Claude Code and Codex when the control channel is exit 2 plus a stderr reason — on the shared tool, prompt, and `Stop`/`SubagentStop` events (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`) that path blocks identically on both, needs no dialect branching, and ports verbatim. Divergence begins the moment a hook injects context or rewrites a value through stdout JSON: the per-event output dialect differs, and a payload written for one provider no-ops on the other. One canonical body plus a thin per-provider adapter survives this — the body reads the shared stdin shape and decides, the adapter normalizes the dialect on the way out for the provider that needs it.

## [01]-[DIVERGENCE]

| [INDEX] | [AXIS]          | [CLAUDE_CODE]                                    | [CODEX]                                                  |
| :-----: | :-------------- | :----------------------------------------------- | :------------------------------------------------------- |
|  [01]   | Events          | Thirty across the full lifecycle                 | Ten; no team, task, or file tier                         |
|  [02]   | Handlers        | `command`, `http`, `mcp_tool`, `prompt`, `agent` | `command` only; others parse and skip                    |
|  [03]   | Async           | `async` and `asyncRewake`                        | Parsed and skipped; every hook is synchronous            |
|  [04]   | Tool coverage   | Every tool                                       | `Bash`, `apply_patch`, and MCP calls only                |
|  [05]   | Turn-complete   | `Stop`/`SubagentStop`, `Notification`            | `Stop`/`SubagentStop` on bus; `notify` is separate       |
|  [06]   | Input transport | One JSON object on stdin                         | One stdin object, strict per-event schema                |
|  [07]   | Terminal escape | `terminalSequence` JSON field                    | None; notifications ride `tui.notifications`             |
|  [08]   | Per-turn key    | `prompt_id` (UUID)                               | `turn_id` (present on every event except `SessionStart`) |

Codex's stdin shape is a strict superset-safe overlay: `session_id`, `transcript_path`, `cwd`, `model`, `permission_mode`, and `hook_event_name` map name-for-name onto Claude's, and Codex adds `turn_id` additively — a body reading the shared fields ignores `turn_id` harmlessly, so the same stdin parse serves both. A subagent hook reuses the parent `session_id` on both providers. Environment variables are not part of this shared overlay — only the stdin object is certified across providers, and Codex is never confirmed to export `CLAUDE_PROJECT_DIR`. So a provider-blind body derives its project root from the stdin `cwd`, never from `os.environ["CLAUDE_PROJECT_DIR"]`: a security gate that measures its sandbox against a `CLAUDE_PROJECT_DIR` that silently falls back to `os.getcwd()` under Codex relaxes the one root it must hold constant. Root off `cwd`, and env-var reads stay adapter-scoped where the adapter can guarantee them.

## [02]-[OUTPUT_DIALECTS]

Codex runs two block dialects that are not interchangeable, and a generator must emit the exact one per event or the hook no-ops:

| [INDEX] | [CODEX_EVENT]           | [DECISION_SURFACE]                                                            | [ADAPTER]             |
| :-----: | :---------------------- | :---------------------------------------------------------------------------- | :-------------------- |
|  [01]   | `SessionStart`          | `hookSpecificOutput.additionalContext`                                        | passthrough           |
|  [02]   | `UserPromptSubmit`      | `decision: "block"` + `reason`; `hookSpecificOutput.additionalContext`        | passthrough           |
|  [03]   | `PreToolUse`            | `hookSpecificOutput.permissionDecision` (`allow`/`deny` only), `updatedInput` | `defer`/`ask`->`deny` |
|  [04]   | `PostToolUse`           | Top-level `decision: "block"` (replaces the result), no `updatedToolOutput`   | translate             |
|  [05]   | `PermissionRequest`     | `hookSpecificOutput.decision.behavior` (`allow`/`deny` only)                  | rebuild               |
|  [06]   | `Stop` / `SubagentStop` | Exit-2 + stderr native, or top-level `decision: "block"` + `reason`           | passthrough           |

`[ADAPTER]` names why each event reaches or skips a `jq` branch: `passthrough` events share their shape byte-for-byte with Claude, so the adapter's `else .` is correct by identity — `SessionStart`, `UserPromptSubmit`, and the exit-2 `Stop`/`SubagentStop` family all ride it; `translate` events (`PreToolUse` `defer`/`ask`->`deny`, `PostToolUse` redaction block, `PermissionRequest` rebuild) diverge and carry an explicit branch. A maintainer reading `translate` knows the branch is load-bearing, never incidental.

On Claude, `PreToolUse` also accepts a top-level `decision: "approve"/"block"`; on Codex only `decision: "block"` lands, since `approve`, `permissionDecision: "ask"`, `continue`, and `stopReason` are parsed-but-unsupported and fail the hook open — so a gate maps `ask`/`defer` to `deny`, never `ask`. Codex `PermissionRequest` reserves `interrupt`, `updatedInput`, and `updatedPermissions` and fails closed if any is set, so the rewrite Claude's `PermissionRequest` accepts is a Codex trap — rewrite at `PreToolUse` instead, which both providers honor. Codex `PostToolUse` skips `updatedToolOutput`; its `decision: "block"` instead replaces the tool result with the reason, so block-and-summarize redacts on Codex where the same block leaves the raw output in context on Claude — one canonical body emits Claude's `updatedToolOutput` and the adapter translates it to a Codex `decision: "block"` carrying the scrubbed render. Common output envelope (`continue`, `stopReason`, `suppressOutput`, `systemMessage`) is identical on both.

## [03]-[CANONICAL_BODY_PLUS_ADAPTER]

One adapter owns the dialect: the body always emits Claude's dialect and is provider-blind, reading stdin once into a typed payload, deciding, and either exiting 2 with a stderr reason or writing Claude JSON. That adapter is a thin shell that pipes the provider's payload into the body, the only surface that translates a dialect on the way out. Splitting that ownership — a body that shapes its own dialect and an adapter that then re-translates it — double-translates and corrupts the output.

- [EXIT_2_PATH]: A body that only ever blocks via exit 2 on the tool, prompt, and `Stop`/`SubagentStop` events needs no adapter — the same executable wires directly into both `settings.json` and `hooks.json`, since Codex honors the Stop-family exit-2 natively. This is the default for every gate, guardrail, and completion loop; reach for stdout JSON only when the hook must rewrite or inject.
- [STDOUT_PATH]: A body that injects context or rewrites emits Claude's dialect natively and the adapter rewrites it to Codex's dialect with `jq`, keyed on `hook_event_name`. That adapter never mutates stdin; the additive `turn_id` passes through untouched.
- [REWRITE_RULES]: At `PermissionRequest`, the adapter rebuilds `decision` fresh with only `behavior` and `message`, dropping the reserved `updatedInput`, `updatedPermissions`, and `interrupt` that Codex fails closed on; at `PreToolUse` `defer` and `ask` remap to `deny`, since Codex parses neither and fails open on the tool call; `terminalSequence` and any Claude-only event the body targets drop whole.
- [POSTTOOL_REDACT]: At `PostToolUse` the adapter flattens Claude's `updatedToolOutput` into a Codex `decision: "block"` whose `reason` carries the scrubbed render — a string passes through, a structured `{stdout, stderr, …}` object joins its text fields — so redaction holds on both providers, though Codex loses the structure Claude keeps.
- [BRAND]: That adapter exports `HOOK_PROVIDER=codex` as a body-side routing and telemetry tag only — the body reads it to stamp its event envelope's `source`, never to shape stdout. Matcher-level tool aliasing handles the `apply_patch`-versus-`Edit` name split; the body never remaps `tool_name`.
- [STRICT_MODE]: That adapter is an executable shell script carrying the estate's shell contract — `set -Eeuo pipefail`, `shopt -s inherit_errexit`, and a named `ERR` trap. One localized-failure fence around the body call drops the `ERR` trap for that call and restores it after, since the body's non-zero exit is captured intent, not an error to trace; shellcheck-clean is necessary but not the whole bar.

Its codex-adapter template is the worked form; the dispatch-daemon example shows the priority-banded registry that routes every event through one entry point.

## [04]-[CODEX_PLACEMENT]

Codex hooks are enabled by default (disable with `[features].hooks = false`) and load from four roots plus enabled-plugin bundles: `~/.codex/hooks.json`, `~/.codex/config.toml`, `<repo>/.codex/hooks.json`, and `<repo>/.codex/config.toml`. Repo-scoped `.codex/` loads only for trusted projects, and a restart re-scans. `hooks.json` shape matches Claude's `settings.json > hooks`; the inline TOML form is an array-of-tables with a nested `.hooks` sub-table:

```toml template
[[hooks.PreToolUse]]
matcher = "Bash|apply_patch"

[[hooks.PreToolUse.hooks]]
type = "command"
command = '/usr/bin/env python3 "$(git rev-parse --show-toplevel)/.codex/hooks/guard.py"'
timeout = 30
statusMessage = "Checking command"
```

Trust is recorded against the hook's SHA: a new or changed hook is marked for review and skipped until trusted through the `/hooks` browser; `--dangerously-bypass-hook-trust` runs enabled hooks once without persisting trust. Managed hooks (policy-trusted) cannot be user-disabled. `Bash|apply_patch` is the portable file-plus-shell matcher, since Codex's `apply_patch` is the tool Claude calls `Edit`/`Write`. Codex runs `Stop`/`SubagentStop` on the hook bus at turn scope, so a dual-provider completion hook ports directly; `notify = ["prog", "lane"]` is a separate legacy notification channel beside the bus, spawning `prog` with one JSON argument at turn end for a desktop or attention signal, never the turn-done hook.

## [05]-[COMPONENT_HOOK_PORT]

A skill or subagent that ships hooks in its frontmatter carries those hooks to both providers. Codex reuses the Claude plugin layout — it sets `CLAUDE_PLUGIN_ROOT` and `CLAUDE_PLUGIN_DATA`, and a component's `PreToolUse`/`PostToolUse`/`Stop` frontmatter hook fires the same command body under both harnesses. A frontmatter hook block ports verbatim when its bodies obey the exit-2 path; a body that rewrites through stdout JSON needs the adapter beside it exactly as a standalone hook does. Codex reads `name` and `description` from the component and ignores Claude-only frontmatter keys as inert, so the hook block travels with the component and the full skill-bundle packaging contract belongs to the skill-writer and codex skills.
