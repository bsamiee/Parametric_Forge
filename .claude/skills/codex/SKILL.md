---
name: codex
description: Dispatch work to the Codex CLI (gpt-5.5) via `codex exec` / `codex review` — each run executes in an isolated context and returns only a report, and usage is effectively free, so prefer it over Claude subagents for self-contained legs. Trigger whenever a leg is transcript-heavy or mechanical - repo sweeps, audits, investigation, many-file reads, log or dataset distillation, live web research, bulk clear-spec implementation, migrations - and for an independent second perspective on any plan, diff, or implementation. Also trigger whenever the user references codex, gpt-5.5, OpenAI models, or asks to offload work or conserve usage; delegation across Claude's own surfaces belongs to agent-dispatch, and Gemini second-model calls belong to agy.
---

# Codex Dispatch

`codex exec` runs gpt-5.5 as a non-interactive agent in its own context window and returns one final message. Defaults come from `~/.codex/config.toml` — gpt-5.5 at medium reasoning — so a bare invocation is already correctly configured; pass flags only to deviate.

Authoring skills FOR codex — the on-disk format, discovery roots, trigger mechanics, `agents/openai.yaml`, and the deltas from Claude-side skills — is [references/authoring-skills.md](references/authoring-skills.md); open it when creating or porting a skill into `~/.codex/skills`, `~/.agents/skills`, or a repo `.agents/skills`. Choosing WHERE work runs across Claude's own surfaces (subagent, fork, team, workflow) is the agent-dispatch skill; this skill owns the codex leg once dispatch picks it.

## [01]-[DISPATCH]

- Exploration and investigation legs (repo sweeps, dependency audits, log distillation, data analysis) whose raw transcripts flood the current context — codex absorbs the reading and returns the conclusion.
- Bulk mechanical implementation with a clear spec: migrations, renames, format conversions, boilerplate expansion.
- Independent second perspective on a plan, implementation, or diff — a different model lineage catches different failure modes.
- Research legs needing live sources: add `-c web_search="live"`.
- Long-running work that must not occupy this session: run in the background against a report file.

Keep in Claude: work inseparable from conversation context too large to restate, and anything mid-flight with the user where iteration latency dominates.

## [02]-[INVOCATION]

```bash
codex exec -s <sandbox> --skip-git-repo-check [-C <dir>] [-o <report>] "<prompt>" </dev/null 2>/dev/null
```

- `</dev/null` is mandatory from a harness: even with a prompt argument, `codex exec` reads piped stdin to EOF (appended as a `<stdin>` block) and blocks forever if stdin is open but silent. Symptom: zero output, zero CPU, indefinite hang. The stderr line `Reading additional input from stdin...` prints before the read even under `</dev/null` — pre-EOF notice, not a hang.
- `2>/dev/null` drops thinking tokens; keep stderr only when diagnosing a failing run.
- `--skip-git-repo-check` always.
- Always pass `-s` explicitly — user config sets a global sandbox default, so an unstated sandbox is whatever config last said, not read-only.
- The final message prints to `stdout`; the banner and reasoning stream go to stderr. Capture a synchronous run's result straight from stdout — `out=$(codex exec -s read-only … "<prompt>" </dev/null 2>/dev/null)` — clean, no banner. Even a heavy read (a full doctrine plus catalogue tiers) returns in a few minutes, well inside the 10-minute Bash ceiling, so synchronous capture is the default; reach for `-o` only when backgrounding.
- Background a long leg with a bare `&`: `codex exec … -o <report> "<prompt>" </dev/null >/dev/null 2><report>-stderr.log &` — the bare `&` form survives the launching shell's exit; never prepend `nohup` (a redirect-less `nohup` writes a stray `nohup.out`), stdout goes to `/dev/null`, and the stderr log's tail IS the crash reason when a run dies with no report. Fleet-grade lanes upgrade this form with `--json` events and a notify push — [06]-[SIGNALS].
  - The bare `&` outlives a wrapper agent's return — a workflow lane's codex runs on after its launch-only wrapper exits — but a main-loop foreground Bash call reaps the child minutes after the call returns (empirical: a detached lane wrote 1.3MB of stderr then died reportless). From the main loop, run codex SYNCHRONOUSLY inside a `run_in_background` Bash task with promote-on-finish — the background task is the keeper.
  - Poll a detached leg by its signals ladder ([06]); process liveness (`pgrep -f "<report-basename>"`) is the RUNNING check, and an absent report while the process lives is normal — never relaunch a live run. Liveness is not health: a process alive far past its tier deadline with no report and near-zero CPU accumulation (`ps -p <pid> -o time=`) is WEDGED — kill it (`pkill -f "<report-basename>"`) and relaunch once; a second wedge is the failure.
- `--output-schema` is STRICT: every key in `properties` must also appear in `required` (`additionalProperties: false`; a conditional field is required-but-empty) — anything less 400s `invalid_json_schema` and the run silently degrades to unvalidated output. Write task and schema files with a real file-write (never a shell heredoc) at ABSOLUTE paths — cwd drift plus heredoc quoting land files where codex cannot find them, and the launch dies instantly on the missing schema.
- A detached typed leg owns its artifacts in one ephemeral folder, purged of stale report/stderr before launch (a leftover report reads as instant completion with last run's data): `task.md` (quoting-proof prompt channel), `schema.json` (`--output-schema` takes only a file path), `report.json` (`-o`), `stderr.log` (crash reason), and — on fleet-grade lanes — `events.jsonl` (`--json` stdout). A short SYNCHRONOUS leg needs zero files: inline prompt, stdout capture.

| [INDEX] | [NEED]                                        | [FLAGS]                                                                               |
| :-----: | :-------------------------------------------- | :------------------------------------------------------------------------------------ |
|  [01]   | Read, analyze, research                       | `-s read-only`                                                                        |
|  [02]   | Edit files in the workspace                   | `-s workspace-write`                                                                  |
|  [03]   | Extra writable roots alongside the workspace  | `--add-dir <dir>`                                                                     |
|  [04]   | Network or system access beyond the workspace | `-s danger-full-access` — only with explicit user authorization                       |
|  [05]   | Run rooted in another directory               | `-C <dir>`                                                                            |
|  [06]   | Durable report artifact                       | `-o <file>` — an empty file means the process was killed before completion            |
|  [07]   | Typed JSON final message                      | `--output-schema <schema.json>`                                                       |
|  [08]   | Live web search                               | `-c web_search="live"` — default `cached` answers from an OpenAI index, no live fetch |
|  [09]   | Attach images (screenshots, diagrams)         | `-i <file>` (repeatable)                                                              |
|  [10]   | Zero-config lane (no MCP fleet, no notify)    | `--ignore-user-config` — auth and skills kept; RESTATE the effort tier                |
|  [11]   | Fan-out legs with no session persistence      | `--ephemeral` — not resumable                                                         |
|  [12]   | Streamed JSONL events for live monitoring     | `--json` (thread/turn/item events to stdout; composes with `-o`)                      |
|  [13]   | Per-lane completion push                      | `-c 'notify=["<sink>","<lane>"]'` — fires at turn end with a JSON payload             |
|  [14]   | Config canary                                 | `--strict-config` — unknown config fields and `-c` keys fail fast                     |

## [03]-[MCP_SELECTION]

MCP selection is GRADED — pick the tier by what the task actually calls, never default to the full fleet:

| [INDEX] | [TIER]     | [INVOCATION]                                              | [BEHAVIOR]                                                                                                |
| :-----: | :--------- | :-------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------- |
|  [01]   | FULL FLEET | bare invocation                                           | Every `[mcp_servers]` row plus every plugin server spawns as a child; slowest startup; fail-closed hazard |
|  [02]   | SELECTED   | `-c 'mcp_servers.<name>.enabled=false'` per unused server | Disabled servers spawn no child and expose no tools; the rest of config.toml stays live                   |
|  [03]   | NONE       | `--ignore-user-config -c model_reasoning_effort="<tier>"` | config.toml skipped wholesale; zero MCP children; effort resets — always restate the tier                 |

- `--ignore-user-config` drops MCP, plugins, notify, and the trust table; auth, the gpt-5.5 default, and ALL skills survive the skip.
- FAIL-CLOSED HAZARD: a `required = true` server that misses its `startup_timeout_sec` handshake kills the whole run at session creation — `thread/start failed`, exit 1, no model turn, no report, ZERO JSONL events. One unreachable required server (a down VPS behind a stdio bridge) fails every full-fleet lane on the machine; the rescue is `-c 'mcp_servers.<name>.enabled=false'` on lanes that do not call it. Disable required servers first when trimming.
- `-c 'mcp_servers={}'` is a merge NO-OP — `-c` table overrides deep-merge, so an empty table clears nothing and the fleet still spawns.
- Tool-level `enabled_tools` allowlists are schema-valid but blank the server's ENTIRE toolset regardless of the names given (probed with both server-side and normalized tool names) — selective granularity stops at the server level.
- A repo-root `.codex/config.toml` shapes every codex run rooted in a TRUSTED project — trust comes from the `[projects]` table in the user config; a `-c 'projects.….trust_level'` grant does not activate it. Precedence is `-c` flag over project file over user config — a `-c 'mcp_servers.<name>.enabled=…'` override beats a stray repo config row in either direction.
- Codex configuration is home-only: `~/.codex` owns config, estate repos are all trusted, and lane shaping rides flags. A project-local `.codex/` directory is a defect — port any load-bearing row to `~/.codex`, then delete the directory.
- Tier overrides compose: `-c 'mcp_servers.<name>.enabled=false'` holds under `--profile`, so SELECTED trimming and the xhigh tier ride one invocation.
- `--strict-config` validates every config row and `-c` override against the installed binary (`unknown configuration field` fails fast, even under `--ignore-user-config`) — put it on fleet canaries, keep it off steady-state lanes.
- Fleet startup stderr carries two harmless lines — an rmcp `worker quit with fatal ... AuthRequired` for any OAuth MCP server not logged in, and `failed to install system skills ... Directory not empty (os error 66)` when concurrent codex startups race on reinstalling `~/.codex/skills/.system`. Neither is a run failure; never treat them as a crash reason.

## [04]-[EFFORT]

| [INDEX] | [TIER] | [SELECT]                           | [USE]                                                                          | [TIMEOUT] |
| :-----: | :----- | :--------------------------------- | :----------------------------------------------------------------------------- | :-------- |
|  [01]   | medium | default                            | extraction, reformatting, bulk clear-spec mechanical legs, standard delegation | 300s      |
|  [02]   | high   | `-c model_reasoning_effort="high"` | hard research, review, and design legs                                         | 600s      |
|  [03]   | xhigh  | `--profile xhigh`                  | the hardest single runs — depth over throughput, multi-minute latency          | 1200s     |

The medium default lives in config.toml, not the binary — `--ignore-user-config` lanes run at effort NONE unless the tier is restated with `-c model_reasoning_effort="<tier>"`. Codex emits its result only at completion — there is no partial output to salvage from a killed run. Run synchronously with the Bash timeout set to the tier; for high and xhigh legs prefer background execution against the signals ladder.

## [05]-[PROMPT_CONTRACT]

Codex shares no conversation state — every prompt is self-contained. Include: the goal, absolute paths, scope bounds and what must not be touched, constraints that matter, and an explicit final-message contract ("Final message: a report with sections X, Y, Z" or an `--output-schema` file). For edit runs, name the acceptance signals codex must run before finishing (build, test, lint commands).

## [06]-[SIGNALS]

Detached lanes carry machine-readable completion signals; report-file existence is the fallback witness, never the primary. The fleet-grade launch:

```bash
codex exec -s <sandbox> --skip-git-repo-check --json -o <report> \
  -c 'notify=["<sink>","<lane>"]' "<prompt>" </dev/null ><events.jsonl> 2><stderr.log> &
```

- `--json` streams JSONL to stdout (route it to the lane's `events.jsonl`; stderr stays the crash log; `-o` still writes the report). Event sequence: `thread.started{thread_id}` (the resume id), `turn.started`, `item.started`/`item.completed` (item types: `agent_message` — the final message text, `reasoning`, `command_execution{command,aggregated_output,exit_code,status}`, `mcp_tool_call`, `web_search`, `file_change`, `error`), then `turn.completed{usage{input_tokens,cached_input_tokens,output_tokens,reasoning_output_tokens}}` or `turn.failed`.
- An `item.type=="error"` item is NOT a run failure — the skills-listing-budget warning rides one on every run under a large skill library. Classify by turn events only.
- `notify` is the push channel: the sink program runs at turn end with its configured leading args followed by ONE JSON arg — `{"type":"agent-turn-complete","thread-id":…,"turn-id":…,"cwd":…,"client":"codex_exec","input-messages":[…],"last-assistant-message":…}`. The `-c` override rides the CLI layer, so it works under `--ignore-user-config` and replaces the user-config notify for that run.
- The estate sink is a keeper-written three-liner that appends `"$@"` plus a timestamp to ONE fleet `events.log` — lane id, resume id, and final-message headline arrive as a single ledger line per completion.
- CLASSIFICATION LADDER, applied per lane in order: `turn.completed` in events + non-empty report → READY; `turn.failed` in events → FAILED with the event message; process gone + empty events file → DEAD, the stderr tail is the reason (pre-thread deaths — config errors, required-MCP init — emit ZERO JSONL and never fire notify); process alive + no turn event → RUNNING (wedge check per [02]).
- `turn.completed.usage` is the fleet's token ledger — sum it across lanes' events files for per-run accounting; codex tokens stay invisible to Claude-side budgets.

## [07]-[SESSIONS]

Every run prints `session id: <uuid>` in its banner (under `--json`, `thread.started.thread_id` carries the same id) — capture it whenever follow-up is plausible.

- Resume: `codex exec resume <session-id> "<follow-up>" </dev/null 2>/dev/null`. Config flags sit between `exec` and `resume`; a resumed session inherits the original model, effort, and sandbox.
- `resume --last` resolves to the newest recorded session — valid only when nothing else ran in between; under any concurrency resume by explicit id.
- Iterative deep work is one session resumed with sharpened prompts, not fresh runs re-paying the exploration cost.
- `--ephemeral` runs record nothing and cannot be resumed.

## [08]-[REVIEW]

`codex review` runs an independent non-interactive code review; the positional prompt sets focus, omitted for a general pass.

| [INDEX] | [SCOPE]                       | [COMMAND]                                                                                                                                                   |
| :-----: | :---------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|  [01]   | Staged + unstaged + untracked | `codex review --uncommitted "<focus>"`                                                                                                                      |
|  [02]   | Branch against a base         | `codex review --base <branch>` — the CLI rejects a prompt alongside `--base`; a FOCUSED range review routes through `codex exec` with an explicit diff task |
|  [03]   | One commit                    | `codex review --commit <sha> "<focus>"`                                                                                                                     |

A fleet-grade review lane runs `codex exec review` instead — the same scope flags plus `--json` events, `-o`, and `--output-schema` typed findings, so a detached review composes with the signals ladder ([06]) like any other lane.

## [09]-[FAN_OUT]

Independent scopes run as concurrent `codex exec` processes, one per scope, each launched fleet-grade ([06]) with its own report, events, and stderr files. Reconcile the reports after all complete. Sandbox isolation is per-process; concurrent workspace-write runs against overlapping paths collide — partition write scopes or serialize them.

A large fleet runs as ONE launcher script in a `run_in_background` Bash task: prompts written to files, lanes pooled with `wait -n` against a max-concurrency cap, the notify sink and ledger written by the same keeper, promotion at the end — launcher and harvester in the same keeper. The keeper's exit code proves nothing about lanes: a spawn-time defect (missing wrapper binary, bad flag) kills every lane in seconds while the keeper still exits 0 and its ledger reads all-FAILED. Verify the fleet within a minute of launch — `pgrep -f 'codex exec'` count at or near the cap plus a clean first stderr log — before trusting it. Never wrap lanes in `timeout`: a deadline kill discards the whole run — codex emits only at completion, so there is no partial result to salvage; hang protection is the wedge check (CPU-time vs wall-time) in [02], or a manual kill of a stalled lane.

## [10]-[WORKFLOWS]

`agent()` accepts only Claude models — a workflow dispatches codex through a thin wrapper agent (`model: 'sonnet', effort: 'low'`, label prefixed `gpt-5.5:`) whose sole job is dispatch-and-receipt: compose the codex command, run it, and return only the thin receipt {ok, report, entries, headline, failure} for the on-disk product — never relaying, re-doing, or re-judging the work. Pick the sandbox by modality — `-s read-only` for a read/research leg, `-s workspace-write` for a write/edit leg. A short leg runs synchronously under a tier-matched Bash timeout and returns codex's stdout. A long leg launches DETACHED fleet-grade ([06]) and returns a LAUNCH receipt immediately — inside a workflow the wrapper never waits: subagent Bash blocks foreground `sleep`, background tasks never notify a workflow subagent, and idle no-op calls trip the runtime's no-progress enforcement, which force-returns the wrapper with a FALSE failure while codex runs on and the report lands with no promoter (`stallMs` does not license idling). The orchestrator owns time: `await new Promise((r) => setTimeout(r, INTERVAL))` between harvest rounds, each round one short-lived agent that classifies every pending lane by the signals ladder ([06]) and promotes READY reports mechanically (jq extract to the durable path), marks DEAD lanes with the stderr tail, and returns the pending set. An absent report while the codex process lives is normal — wait another round, never relaunch a live run; only a DEAD lane is worth one relaunch. Codex tokens never count toward `budget.spent()`.

## [11]-[JUDGMENT]

Codex output is a colleague's, not an oracle's. Verify load-bearing claims against source or current documentation before acting on them; push back through a session resume, identified as Claude, with evidence — both lineages produce errors. A non-zero exit is reported verbatim; retry only with a changed command. A run that dies with "ran out of room in the model's context window" is OVER-SCOPED, not transient — split the task into narrower sequential lanes (research vs design; sweep vs synthesis) whose later lanes read the earlier lanes' report files; relaunching as-is fails identically.
