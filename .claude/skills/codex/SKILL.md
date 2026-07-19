---
name: codex
description: Dispatch self-contained work to Codex (gpt-5.6 Sol/Terra) through the `codex` MCP tool or the `codex` CLI — an isolated agent returning one report; writes, design, hard reviews, fleet fix waves, research, and volume extraction all ride it. Trigger on repo sweeps, audits, investigation, log or dataset distillation, live web research, implementation from spec, migrations, a second perspective on any plan or diff, any mention of codex, gpt-5.6, Sol, Terra, or OpenAI models, and any request to offload work or conserve usage. Claude-surface delegation belongs to agent-dispatch; Gemini calls belong to agy.
---

# [CODEX]

`codex exec` runs a gpt-5.6 model as a non-interactive agent in its own context window and returns one final message. Model and effort come from `~/.codex/config.toml`. Use `openaiDeveloperDocs` MCP server for all configuration or usage questions.

## [01]-[DISPATCH]

Main-loop legs run as background CLI keepers — a blocking MCP call freezes the session with zero visibility. Image legs ride the CLI `-i`; the MCP tool takes no image parameter.

- Investigation legs whose transcripts flood this context — repo sweeps, audits, log distillation, data analysis: codex returns the conclusion.
- Fleet fix and critique waves: concurrent write lanes draining findings under lane law, each with disjoint write territory.
- Critique lanes writing on-disk fixlogs, reports, or dossiers another agent consumes downstream.
- Implementation from spec: migrations, renames, conversions, boilerplate expansion, full features with enumerated moves.
- Independent second perspective on a plan, implementation, or diff — a different model lineage catches different failure modes.

## [02]-[PROMPTING]

Codex is maximally literal, it follows a clean contract exactly and exhaustively, ambiguity or implicit intent burns tokens reconciling scope. Role envelope ranks the two dispatch channels (system > developer > user), so where a directive lands sets its authority. Leaner prompts outperform. Every directive must earn its slot, one directive per concern, and a directive codex already ships is a conflict risk, NOT reinforcement.

[BLOCK_VOCABULARY] — one block per concern, in this order; a block's name states its lane, and a lane omits blocks it has no logic for:

| [INDEX] | [BLOCK]                | [JOB]                                                                                       |
| :-----: | :--------------------- | :------------------------------------------------------------------------------------------ |
|  [01]   | `<role>`               | identity, territory, hard exclusions; judgment lanes add findings-are-untrusted             |
|  [02]   | `<completion_bar>`     | done-definition per deliverable with its proof; sits early, where it beats early-stop       |
|  [03]   | `<context_gathering>`  | read ladder, total tool-call budget, uncertainty escape hatch                               |
|  [04]   | `<decision_procedure>` | refute-first adjudication — verdict lanes                                                   |
|  [05]   | `<capability_mandate>` | surface-raising stated as measurable conditions — campaign lanes                            |
|  [06]   | `<verification>`       | post-edit re-read plus batched command checks; cite-check on recon, rubric walk on judgment |
|  [07]   | `<output_contract>`    | JSON-only shape, null-for-missing — always LAST                                             |

[DEVELOPER]: Durable lane law as named XML blocks — MCP `developer-instructions` / CLI `-c developer_instructions="…"`:

```text template
<role>
<identity>. Territory: <territory>; never <exclusions>. <invariants>.
</role>

<completion_bar>
Done is <deliverables>, each proven by <evidence>. Implement exactly and only <moves>; choose the simplest valid interpretation of any ambiguity. A blocked deliverable returns <blocked-entry>, never a partial edit. Your layer is <layer>; out-of-layer discoveries land as <typed-rows>, never edits.
</completion_bar>

<context_gathering>
Read fully, in order: <ladder>.
Budget: at most <N> tool calls total; never concatenate the territory into one command.
Stop when the product is complete; uncertainty left at the budget lands in <uncertainty-slot>, never re-reads.
</context_gathering>

<decision_procedure>
<adjudication>
</decision_procedure>

<capability_mandate>
<expansions>
</capability_mandate>

<verification>
Re-read each changed region after landing it. <checks>, run once, batched, after the final edit. A check not run is never claimed as run.
</verification>

<output_contract>
Your final message is a single JSON object with exactly this shape:
<shape>
JSON only — no prose outside it, no code fences; every key shown is required; null for a value you could not determine, [] for an empty list, never guess.
</output_contract>
```

[USER]: Task instance plus any imperative spawn step — MCP `prompt` / the CLI positional argument; the spawn step appears only on a fan-out lane:

```text template
Goal: <outcome>.
Context: <inputs>.
Constraints: <bounds>.
Done when: <deliverables>.

Before <anchor>, spawn exactly <N> parallel sub-agents with collaboration.spawn_agent, one per <split>; collect every one with collaboration.wait_agent before <synthesis>. Each spawn task is self-contained — absolute paths, <mandate>, return shape <shape>. Sub-agents read and report only; their returns are candidate data you judge under your own law.
```

[CALIBRATION]: When a lane misbehaves, repair the contract surgically; reproduce with the failing developer message plus a small batch of failure examples, then make small explicit edits — clarify conflicting rules, remove redundant lines — one change at a time:
- Budget caps TOTAL tool calls, never per-file reads; per-file causes the lane to aggregate the territory into one truncating command and completeness collapses.
- Ambiguity resolves by instruction, never by inviting questions — a headless lane has nobody to ask.
- Autonomy states ONCE, naming safe actions — repeated "ask first" or "do not mutate" phrasing causes spurious approval pauses.
- Reserve ALWAYS/NEVER for true invariants (JSON-only, territory bans, no-git); phrase judgment calls as decision rules.
- Done-claims name observable evidence from the real surface; "tests pass" or "checks ran" alone is not evidence.
- Iterative deep work continues ONE thread with sharpened prompts; a follow-up turn carries only the delta.

[EXCLUSIONS]: What never enters a lane prompt:
- Persistence blocks ("keep going until fully resolved") — the completion bar carries the anti-premature force, and a bare push amplifies scope.
- Chain-of-thought scaffolding and plan-narration preambles.
- Intensifier stacks ("THOROUGH", "exhaustive") — measured to cause tool over-use.
- Per-file read caps and "read each file at most once" phrasing.
- Hostile-stance paragraphs and estate-register law verbatim — a lane takes de-conflicted, task-scoped law.
- Broad write authority — the writable directory is the lane's whole world; cross-territory obligations belong to the caller.
- "Ask if unclear", "you may spawn", and every other permissive form whose imperative twin is the working one.

## [03]-[INVOCATION]

[MCP_SURFACE] — server `codex`, tools `codex` and `codex-reply`; the prompt rides a tool argument, no shell quoting:
- `base-instructions` (MCP) / `model_instructions_file` (CLI) REPLACE the shipped system prompt — deliberate use only, never a lane-law channel.
- MCP tool calls serialize within a lane; CLI lanes with native tools parallelize reads.
- Heavy MCP tool call issued from INSIDE a codex turn can wedge the lane, pin nested lookups to `get_latest_package_version`.
- Parameters: `prompt`, `model`, `cwd`, `approval-policy`, `config` (object — effort deviates via `{"model_reasoning_effort": "..."}`), `developer-instructions`, `base-instructions`, `compact-prompt`. A headless dispatch passes `approval-policy: "never"`.
- Result envelope `{threadId, content}`: parse `content` for the final message — a consumer treating the raw result as the product double-encodes every downstream read; `threadId` feeds `codex-reply` (`conversationId` is its deprecated alias).

[DEFAULT_CLI]:

```bash template
codex exec [-c developer_instructions="<lane-law>"] [-C <dir>] [-o <report>] "<prompt>" </dev/null 2>/dev/null
```

[MODIFIED_CLI]:

```bash template
codex exec [-m <model>] [-c 'model_reasoning_effort="<tier>"'] [-c developer_instructions="<lane-law>"] [-C <dir>] [-o <report>] "<prompt>" </dev/null 2>/dev/null
```

[CLI_SURFACE]: `</dev/null` is mandatory from a harness:
- `codex exec` reads piped stdin to EOF, an open-but-silent stdin blocks forever; stderr `Reading additional input from stdin...` notice is pre-EOF, not a hang.
- `-c developer_instructions="<lane law>"` lands the developer-role message — `-c` is the only CLI path, no flag exists.
- Final message prints to stdout, banner and reasoning to stderr — keep stderr only when diagnosing a failing run.
- Synchronous stdout capture is default — `out=$(codex exec … "<prompt>" </dev/null 2>/dev/null)` — inside the 10-minute Bash ceiling; `-o` when backgrounding.
- Task and schema files land through a real file-write at ABSOLUTE paths, never a shell heredoc — cwd drift plus heredoc quoting results in lost files.

| [INDEX] | [NEED]                                    | [FLAGS]                                                                        |
| :-----: | :---------------------------------------- | :----------------------------------------------------------------------------- |
|  [01]   | Run rooted in another directory           | `-C <dir>`                                                                     |
|  [02]   | Durable report artifact                   | `-o <file>` — an empty file means the process was killed before completion     |
|  [03]   | Typed JSON final message                  | `--output-schema <schema.json>` — validated final-message shape                |
|  [04]   | Live web search                           | `-c web_search="live"` — default `cached` answers from an index, no live fetch |
|  [05]   | Attach images (screenshots, diagrams)     | `-i <file>` (repeatable)                                                       |
|  [06]   | Feature toggles per lane                  | `--enable <feature>` / `--disable <feature>` (repeatable)                      |
|  [07]   | Fan-out legs with no session persistence  | `--ephemeral` — not resumable                                                  |
|  [08]   | Streamed JSONL events for live monitoring | `--json` (thread/turn/item events to stdout; composes with `-o`)               |
|  [09]   | Per-lane completion push                  | `-c 'notify=["<sink>","<lane>"]'` — fires at turn end with a JSON payload      |

## [04]-[MODEL_AND_EFFORT]

Model and effort deviate by flag, `-m` in the CLI, `model` and `config` on the MCP tool; an unstated axis runs the config:
- Sol carries roughly 80% of dispatch — every non-trivial write, deep design, hard reviews, whole fix/critique fleets, second perspectives — and needs no flag.
- Sol at `medium` covers menial file writes — api catalogs and their kin — over terra at any tier.
- Sol at `low` covers volume extraction and classification.
- Terra at `medium`, `-m gpt-5.6-terra` is used for navigation, exploration, and research. `gpt-5.6-luna` is NEVER dispatched.

| [INDEX] | [TIER] | [SELECT]                             | [USE]                                                                                |
| :-----: | :----- | :----------------------------------- | :----------------------------------------------------------------------------------- |
|  [01]   | low    | `-c model_reasoning_effort="low"`    | trivial glue: probes, extraction, classification, relabels                           |
|  [02]   | medium | `-c model_reasoning_effort="medium"` | menial writes and fan-out legs where throughput beats depth                          |
|  [03]   | xhigh  | `-c model_reasoning_effort="xhigh"`  | deeper single-agent reasoning for the hardest investigation, design, and review legs |

- Deviate surgically, one axis at a time: xhigh deepens the single hardest leg, low/medium serve throughput; latency tracks task shape, NOT tier.
- Overrun means CIRCLING — re-verifying unchanged work, loops adding no evidence — never duration; a well-scoped high-tier leg legitimately runs an hour.

## [05]-[BACKGROUND]

Main agent runs codex SYNCHRONOUSLY inside a `run_in_background` Bash task, keeper is the lane's owner, its exit re-invokes the agent. A foreground Bash call reaps its detached children minutes after returning, killing lanes reportless mid-run. Codex emits its result only at completion; the lane runs until it finishes.

```bash template
codex exec --json -o <report> \
  -c 'notify=["<sink>","<lane>"]' "<prompt>" </dev/null ><events.jsonl> 2><stderr.log> &
```

- A detached leg owns one ephemeral folder: `task.md`, `schema.json`, `report.json` (`-o`), `stderr.log`, `events.jsonl` (`--json`).
- Purge stale report and stderr before launch, leftover reports read as instant completion carrying last run's data.
- A bare `&` survives the launching shell; never prepend `nohup`.
- One estate sink appends `"$@"` plus a timestamp to one fleet `events.log` — one ledger line per completion.
- `turn.completed.usage` carries `input_tokens`, `cached_input_tokens`, `output_tokens`, `reasoning_output_tokens`, summed across lanes' events files.
- Liveness is `pgrep -f "<report-basename>"`; health is not liveness, a quiet process with no report and near-zero CPU (`ps -p <pid> -o time=`) is WEDGED.
- `notify` runs the sink at turn end with one JSON argument: `{"type":"agent-turn-complete","thread-id":…,"turn-id":…,"cwd":…,"client":"codex_exec","input-messages":[…],"last-assistant-message":…}`.

[EVENT_STREAM]:
- `thread.started{thread_id}` (the resume id)
- `turn.started`, `item.started`/`item.completed`, then `turn.completed` or `turn.failed`
- `agent_message` carries the final text, `command_execution` carries `{command, aggregated_output, exit_code, status}`
- `item.type=="error"` item is NOT a run failure — the skills-budget warning rides one on every run under a large library; classify by turn events only.

## [06]-[FAN_OUT]

Independent scopes run as concurrent `codex exec` processes, one per scope, each agent with its own artifacts; reconcile reports after all complete. Concurrent write runs against overlapping paths collide — partition write scopes or serialize.

Inside ONE lane, `collaboration.*` is the subagent tool family — `spawn_agent`, `send_message`, `followup_task`, `wait_agent`, `interrupt_agent`, `list_agents`. Children share the workspace live, inherit the model, and inherit NO conversation turns unless `fork_turns` opts in — a spawn task is self-contained like any codex prompt.

- An injected developer-role gate admits children ONLY on imperative spawn wording in the user prompt or AGENTS.md/skill chain.
- Permissive "you may spawn" and `developer_instructions` mandates fail silently with zero spawns.
- grep the parent rollout for `function_call` items named `spawn_agent`, `collab_tool_call` is a stale marker and false-negative.
- Write lane writes its own report as its final act; the caller verifies (`jq -e`) — re-emitting a codex product through another agent's Write is lossy at scale.
- Row-shaped sweep rides ONE lane's `spawn_agents_on_csv`: one worker per CSV row under the concurrency cap, `output_schema` typing each row and `output_csv_path` exporting the combined results.

## [07]-[SESSIONS]

`codex archive <id>` / `unarchive <id>` is the reversible lifecycle; `codex delete` removes one session, its `--force` unreliable across spawned children — bulk cleanup is a date-scoped sqlite prune plus matching rollout deletions plus `VACUUM`. `[features] memories`/`chronicle` rows gate those features independently of corpus deletion.

[STORE]: one rollout per session at `~/.codex/sessions/<YYYY>/<MM>/<DD>/rollout-<ts>-<uuidv7>.jsonl`:
- Filename timestamp is LOCAL time, the payload's is UTC.
- `session_index.jsonl` LAGS live runs, so correlate by datestamped filename.
- Sqlite store filenames embed the migration version (`state_5` today) — resolve the live name, never pin the number.
- Every run mints a resumable thread on both surfaces, capture the id at dispatch (the lane receipt persists it), a continuation inherits model and effort.
- `resume --last` is valid only when nothing else ran in between; under concurrency resume by explicit id. `--ephemeral` runs record nothing.
- MCP: Envelope carries `threadId`; continue with `codex-reply`.
- CLI: Banner prints `session id: <uuid>` (= `thread.started.thread_id` under `--json`); resume with `codex exec resume <id> "<follow-up>" </dev/null 2>/dev/null`, config flags between `exec` and `resume`; `resume --all` surfaces sessions recorded under another cwd.

## [08]-[REVIEW]

`codex review` runs an independent non-interactive review. Scope flags — `--uncommitted`, `--base <branch>`, `--commit <sha>` — are mutually exclusive with each other AND with a focus prompt: a prompt is valid only on bare `codex review`, and every focused scoped review routes through `codex exec` with an explicit diff task. A fleet-grade review lane runs `codex exec review` — the same scope flags plus `--json`, `-o`, and `--output-schema` typed findings, composing with the background keeper like any lane.
