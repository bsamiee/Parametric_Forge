---
name: codex
description: Dispatch work to the Codex CLI (gpt-5.5) via codex exec / codex review — each run executes in an isolated context and returns only a report, and usage is effectively free, so prefer it over Claude subagents for self-contained legs. Trigger whenever a leg is transcript-heavy or mechanical - repo sweeps, audits, investigation, many-file reads, log or dataset distillation, live web research, bulk clear-spec implementation, migrations - and for an independent second perspective on any plan, diff, or implementation. Also trigger whenever the user references codex, gpt-5.5, OpenAI models, or asks to offload, delegate, or conserve usage.
---

# Codex Dispatch

`codex exec` runs gpt-5.5 as a non-interactive agent in its own context window and returns one final message. Defaults come from `~/.codex/config.toml` — gpt-5.5 at medium reasoning — so a bare invocation is already correctly configured; pass flags only to deviate.

Authoring skills FOR codex — the on-disk format, discovery roots, trigger mechanics, `agents/openai.yaml`, and the deltas from Claude-side skills — is [references/authoring-skills.md](references/authoring-skills.md); open it when creating or porting a skill into `~/.codex/skills`, `~/.agents/skills`, or a repo `.agents/skills`.

## When to dispatch

- Exploration and investigation legs (repo sweeps, dependency audits, log distillation, data analysis) whose raw transcripts would flood the current context — codex absorbs the reading and returns the conclusion.
- Bulk mechanical implementation with a clear spec: migrations, renames, format conversions, boilerplate expansion.
- Independent second perspective on a plan, implementation, or diff — a different model lineage catches different failure modes.
- Research legs needing live sources: add `-c web_search="live"`.
- Long-running work that should not occupy this session: run in the background against a report file.

Keep in Claude: work inseparable from conversation context too large to restate, and anything mid-flight with the user where iteration latency dominates.

## Invocation

```bash
codex exec -s <sandbox> --skip-git-repo-check [-C <dir>] [-o <report>] "<prompt>" </dev/null 2>/dev/null
```

- `</dev/null` is mandatory from a harness: even with a prompt argument, `codex exec` reads piped stdin to EOF (appended as a `<stdin>` block) and blocks forever if stdin is open but silent. Symptom: zero output, zero CPU, indefinite hang. The stderr line `Reading additional input from stdin...` prints before the read even under `</dev/null` — pre-EOF notice, not a hang.
- `2>/dev/null` drops thinking tokens; keep stderr only when diagnosing a failing run.
- `--skip-git-repo-check` always.
- Always pass `-s` explicitly — user config sets a global sandbox default, so an unstated sandbox is whatever config last said, not read-only.
- The final message prints to **stdout**; the banner and reasoning stream go to stderr. Capture a synchronous run's result straight from stdout — `out=$(codex exec -s read-only … "<prompt>" </dev/null 2>/dev/null)` — clean, no banner. Even a heavy read (a full doctrine plus catalogue tiers) returns in a few minutes, well inside the 10-minute Bash ceiling, so synchronous capture is the default; reach for `-o` only when backgrounding.
- Background a long leg with a bare `&`: `codex exec … -o <report> "<prompt>" </dev/null >/dev/null 2><report>-stderr.log &`. The bare `&` survives only while its launching SESSION lives — a polling wrapper agent keeps it alive, but a main-loop foreground Bash call reaps the child minutes after the call returns (empirical: a detached lane wrote 1.3MB of stderr then died reportless). From the main loop, run codex SYNCHRONOUSLY inside a `run_in_background` Bash task with promote-on-finish — the background task is the keeper. The bare `&` form survives the launching shell's exit — do NOT prepend `nohup` (a `nohup` without a redirect writes a stray `nohup.out`), and send stdout to `/dev/null` with stderr to a per-run log file (`2><report>-stderr.log`) — the event stream is noise, but that log's tail IS the crash reason when a run dies with no report. Poll the report by liveness (`pgrep -f "<report-basename>"`); an absent report while the process lives is normal, never relaunch a live run. Liveness is not health: a process alive far past its tier deadline with no report and near-zero CPU accumulation (`ps -p <pid> -o time=`) is WEDGED — kill it (`pkill -f "<report-basename>"`) and relaunch once; a second wedge is the failure.
- Every `codex exec` spawns the full `~/.codex/config.toml` MCP server fleet as child processes. `-c 'mcp_servers={}'` does NOT clear it — `-c` table overrides deep-merge, so an empty table is a no-op and the fleet still spawns. File-only and fan-out legs pass `--ignore-user-config` instead: config.toml is skipped wholesale (no MCP fleet, no notify hook), auth and the gpt-5.5/medium defaults survive, and anything else needed rides flags (`-m`, `-c model_reasoning_effort="high"`, `-c web_search="live"`). Surgical single-server removal is `-c 'mcp_servers.<name>.enabled=false'`. Keep the fleet only when the task genuinely calls MCP tools.
- Fleet startup stderr carries two harmless lines — an rmcp `worker quit with fatal ... AuthRequired` for any OAuth MCP server not logged in, and `failed to install system skills ... Directory not empty (os error 66)` when concurrent codex startups race on reinstalling `~/.codex/skills/.system`. Neither is a run failure; never treat them as a crash reason.
- `--output-schema` is STRICT: every key in `properties` must also appear in `required` (`additionalProperties: false`; a conditional field is required-but-empty) — anything less 400s `invalid_json_schema` and the run silently degrades to unvalidated output. Write task and schema files with a real file-write (never a shell heredoc) at ABSOLUTE paths — cwd drift plus heredoc quoting land files where codex cannot find them, and the launch dies instantly on the missing schema.
- A detached typed leg owns exactly FOUR artifacts, each forced by the interface — `task.md` (quoting-proof prompt channel), `schema.json` (`--output-schema` takes only a file path), `report.json` (`-o`), `stderr.log` (crash reason) — homed together in one ephemeral folder, purged of stale report/stderr before launch (a leftover report reads as instant completion with last run's data). A short SYNCHRONOUS leg needs zero files: inline prompt, stdout capture.

| Need                                          | Flags                                                                                 |
| --------------------------------------------- | ------------------------------------------------------------------------------------- |
| Read, analyze, research                       | `-s read-only`                                                                        |
| Edit files in the workspace                   | `-s workspace-write`                                                                  |
| Extra writable roots alongside the workspace  | `--add-dir <dir>`                                                                     |
| Network or system access beyond the workspace | `-s danger-full-access` — only with explicit user authorization                       |
| Run rooted in another directory               | `-C <dir>`                                                                            |
| Durable report artifact                       | `-o <file>` — an empty file means the process was killed before completion            |
| Typed JSON final message                      | `--output-schema <schema.json>`                                                       |
| Live web search                               | `-c web_search="live"` — default `cached` answers from an OpenAI index, no live fetch |
| Attach images (screenshots, diagrams)         | `-i <file>` (repeatable)                                                              |
| Skip config.toml wholesale (no MCP fleet)     | `--ignore-user-config` — auth kept; restate needed config as flags                    |
| Fan-out legs with no session persistence      | `--ephemeral` — not resumable                                                         |
| Streamed JSONL events for live monitoring     | `--json` (thread/turn/item events)                                                    |

## Effort

| Tier   | Select                             | Use for                                                                        | Timeout |
| ------ | ---------------------------------- | ------------------------------------------------------------------------------ | ------- |
| medium | default                            | extraction, reformatting, bulk clear-spec mechanical legs, standard delegation | 300s    |
| high   | `-c model_reasoning_effort="high"` | hard research, review, and design legs                                         | 600s    |
| xhigh  | `--profile xhigh`                  | the hardest single runs — depth over throughput, multi-minute latency          | 1200s   |

Codex emits its result only at completion — there is no partial output to salvage from a killed run. Run synchronously with the Bash timeout set to the tier; for high and xhigh legs prefer background execution polling the `-o` report file, or `--json` to stream progress events.

## Prompt contract

Codex shares no conversation state — every prompt is self-contained. Include: the goal, absolute paths, scope bounds and what must not be touched, constraints that matter, and an explicit final-message contract ("Final message: a report with sections X, Y, Z" or an `--output-schema` file). For edit runs, name the acceptance signals codex must run before finishing (build, test, lint commands).

## Sessions

Every run prints `session id: <uuid>` in its banner — capture it whenever follow-up is plausible.

- Resume: `codex exec resume <session-id> "<follow-up>" </dev/null 2>/dev/null`. Config flags sit between `exec` and `resume`; a resumed session inherits the original model, effort, and sandbox.
- `resume --last` resolves to the newest recorded session — valid only when nothing else ran in between; under any concurrency resume by explicit id.
- Iterative deep work is one session resumed with sharpened prompts, not fresh runs re-paying the exploration cost.
- `--ephemeral` runs record nothing and cannot be resumed.

## Review

`codex review` runs an independent non-interactive code review; the positional prompt sets focus, omitted for a general pass.

| Scope                         | Command                                                                                                                                                     |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Staged + unstaged + untracked | `codex review --uncommitted "<focus>"`                                                                                                                      |
| Branch against a base         | `codex review --base <branch>` — the CLI rejects a prompt alongside `--base`; a FOCUSED range review routes through `codex exec` with an explicit diff task |
| One commit                    | `codex review --commit <sha> "<focus>"`                                                                                                                     |

## Parallel fan-out

Independent scopes run as concurrent `codex exec` processes, one per scope, each with its own `-o` report file and its session id captured from the banner. Reconcile the reports after all complete. Sandbox isolation is per-process; concurrent workspace-write runs against overlapping paths collide — partition write scopes or serialize them.

A large fleet runs as ONE launcher script in a `run_in_background` Bash task: prompts written to files, lanes pooled with `wait -n` against a max-concurrency cap, promotion and a ledger at the end — launcher and harvester in the same keeper. The keeper's exit code proves nothing about lanes: a spawn-time defect (missing wrapper binary, bad flag) kills every lane in seconds while the keeper still exits 0 and its ledger reads all-FAILED. Verify the fleet within a minute of launch — `pgrep -f 'codex exec'` count at or near the cap plus a clean first stderr log — before trusting it. Never wrap lanes in `timeout`: no timeout/gtimeout binary exists on this machine; hang protection is the wedge check (CPU-time vs wall-time) above, or a manual kill of a stalled lane.

## Inside workflows

`agent()` accepts only Claude models — a workflow dispatches codex through a thin wrapper agent (`model: 'sonnet', effort: 'low'`, label prefixed `gpt-5.5:`) whose sole job is dispatch-and-receipt: compose the codex command, run it, and return only the thin receipt {ok, report, entries, headline, failure} for the on-disk product — never relaying, re-doing, or re-judging the work. Pick the sandbox by modality — `-s read-only` for a read/research leg, `-s workspace-write` for a write/edit leg. A short leg runs synchronously under a tier-matched Bash timeout and returns codex's stdout. A long leg launches DETACHED (`… -o <report> "<prompt>" </dev/null >/dev/null 2><report>-stderr.log &` — bare `&`, never `nohup`) and returns a LAUNCH receipt immediately — inside a workflow the wrapper never waits: subagent Bash blocks foreground `sleep`, background tasks never notify a workflow subagent, and idle no-op calls trip the runtime's no-progress enforcement, which force-returns the wrapper with a FALSE failure while codex runs on and the report lands with no promoter (`stallMs` does not license idling). The orchestrator owns time: `await new Promise((r) => setTimeout(r, INTERVAL))` between harvest rounds, each round one short-lived agent that promotes finished reports mechanically (jq extract to the durable path), marks gone-with-no-report lanes DEAD with the stderr tail, and returns the pending set. An absent report while the codex process lives is normal — wait another round, never relaunch a live run; only a gone process with an empty report is worth one relaunch. Codex tokens never count toward `budget.spent()`.

## Judgment

Codex output is a colleague's, not an oracle's. Verify load-bearing claims against source or current documentation before acting on them; push back through a session resume, identified as Claude, with evidence — either model can be wrong. A non-zero exit is reported verbatim; retry only with a changed command. A run that dies with "ran out of room in the model's context window" is OVER-SCOPED, not transient — split the task into narrower sequential lanes (research vs design; sweep vs synthesis) whose later lanes read the earlier lanes' report files; relaunching as-is fails identically.
