# Codex Lanes

Routing a workflow lane to gpt-5.5 through a thin Claude wrapper. The `model` option accepts only Claude models, so a self-contained codex lane (repo sweep, audit, research, mechanical edit) rides a wrapper agent whose ONLY job is dispatch-and-receipt. Dispatch mechanics — flags, config, MCP grading, signals, sessions, effort tiers — are the codex skill's law; this reference carries only the workflow-level composition, and its content tracks that skill.

## [01]-[WRAPPER]

The wrapper runs `model: 'sonnet', effort: 'low'` with a label prefixed `gpt-5.5:` — the workflow UI shows the wrapper's Claude model, so the label is the only indication of the real worker. It writes the task and the product schema to run scratch with the Write tool, launches codex detached fleet-grade (`--json` events plus the notify sink — the codex skill's signals section owns the exact line), and returns the thin RECEIPT — the product stays on disk for the terminal reader. It never performs, edits, judges, softens, summarizes, or relays the work itself.

```js
// TWO schemas: codex gets the PRODUCT schema (via the --output-schema file); the wrapper's
// own schema is the thin RECEIPT — the product body never crosses the wire.
// The wrapper is LAUNCH-ONLY: it returns a launch receipt in seconds; the orchestrator's
// setTimeout harvest loop owns the waiting and the promotion.
const receipt = await agent(codexPrompt('audit-auth', task, PRODUCT_SCHEMA, /*writes*/ false),
  { model: 'sonnet', effort: 'low', label: 'gpt-5.5:audit-auth', schema: RECEIPT })
```

The task file is the quoting-proof prompt channel (`codex exec … "Do the task in <task>.md"` — long prompts through shell argv are the fragility); the `--output-schema` file is what makes codex's report typed JSON. Codex schemas run the OpenAI strict profile — the stricter row of the validator split in the api reference; design conditional fields as required-but-empty (`""`/`[]`). The wrapper writes the task and schema files with the Write tool at ABSOLUTE paths under the repo root (never a shell heredoc — cwd drift and quoting land files where codex cannot find them), and the launch call verifies both with `test -s` before starting codex.

## [02]-[LAUNCH]

Wrappers never wait — a wrapper agent has no legal wait primitive: subagent Bash blocks foreground `sleep`, a blocking `until` loop dies with its one call, background Bash tasks never notify a workflow subagent, and idle no-op calls ("waiting" text, `sleep 1`, `true`) trip the runtime's no-progress enforcement — which force-returns the wrapper with a FALSE `ok:false` while codex runs on and the report lands with no promoter; `stallMs` does not license idling. The wrapper's ONLY job is the launch, finished in seconds:

1. Purge stale artifacts (`rm -f` its own prior `report`/`events`/`stderr` — a leftover report satisfies a poll instantly with LAST run's data).
2. Write the task and schema files; verify with `test -s`.
3. Launch codex DETACHED with a bare `&`, fleet-grade per the codex skill: `--json` stdout routed to the lane's `events.jsonl`, stderr to `stderr.log`, the report via `-o`, stdin closed — never `nohup`.
4. Verify the process is alive (`pgrep -f "<report-basename>"`).
5. Return the LAUNCH receipt `{ok:true, report:'', entries:0, headline:'launched', failure:''}`.

`</dev/null` is non-negotiable — `codex exec` blocks forever on open stdin; the stderr banner `Reading additional input from stdin...` prints even under `</dev/null` and is not a hang. Stderr goes to the lane's `stderr.log`, never a sink — a pre-thread death (config error, required-MCP init) emits ZERO JSONL, so the stderr tail is its only witness. Startup stderr noise that is never a crash reason: an rmcp `AuthRequired` fatal for any OAuth MCP server not logged in (fires whenever the fleet spawns), and a system-skills reinstall race (`Directory not empty (os error 66)`) under concurrent lane launches. `--ephemeral` suits fan-out lanes that never resume.

Sandbox is modality: `-s read-only` for investigation/research/response lanes; `-s workspace-write` when codex must author or edit files — partition write scopes across concurrent wrappers, or keep codex read-only and let a Claude writer apply the edits, because two workspace-write runs over one path collide. Set `-s` explicitly; the config default is not read-only.

A codex lane owns exactly the artifacts the CLI interface forces, under the run-scratch grammar in the patterns reference: `task.md` (the quoting-proof prompt channel), `schema.json` (`--output-schema` accepts only a file path), `report.json` (a detached run needs `-o`), `events.jsonl` (`--json` stdout — `turn.completed`/`turn.failed` is the completion signal, `thread.started.thread_id` the resume id), `stderr.log` (the crash reason for pre-thread deaths). Do not invent more; do not merge them.

## [03]-[HARVEST]

Time lives in the orchestrator: `await new Promise((r) => setTimeout(r, INTERVAL_MS))` between rounds (`setTimeout` is an injected workflow global), then one short-lived harvester agent per round that classifies each pending lane by the codex skill's signals ladder — `turn.completed` in events plus a non-empty report → READY; `turn.failed` → FAILED with the event message; process gone plus an empty events file → DEAD carrying the stderr tail; process alive with no turn event → RUNNING — promotes READY reports mechanically (jq-validate, extract to the durable home, jq-count the receipt fields), relaunches a DEAD lane at most once, and returns `{promoted, dead, pending}`. The loop exits when pending empties or a round cap fires.

- An absent report while the process is alive is NORMAL — the loop waits another round; never relaunch a live run.
- A lane alive far past its expected wall (~20 minutes for a recon lane — concurrent lanes contend for the machine) is WEDGED: the harvester kills it (`pkill -f "<report-basename>"`) and treats it as DEAD.
- The harvester's checks are a PRE-STAGED SCRIPT — one launch wrapper writes `harvest.sh` (the ladder, promote logic, exact pgrep patterns baked in) and every harvest round just executes it and relays its JSON verdict. Prose-described check mechanics get re-derived by each round's fresh agent and botched within a few rounds (empirical: a mis-expanded pgrep pattern declared four live lanes dead).

A short synchronous leg — comfortably inside its tier timeout — needs none of this: one Bash call, stdout capture, no detach.

## [04]-[CONFIG]

MCP on fan-out lanes is GRADED — the codex skill's MCP-selection section owns the full law. Every codex process spawns the full `~/.codex/config.toml` MCP fleet as children: N concurrent lanes start N fleets, and a `required = true` server that misses its startup handshake KILLS the lane at session creation (exit 1, no turn, no report, zero JSONL — the stderr tail is the only witness). File-only lanes pass `--ignore-user-config` AND restate the effort tier (`-c model_reasoning_effort="medium"` — the medium default lives in config.toml and resets to none without it; auth, the gpt-5.5 default, and skills survive; restate other needed config as flags, e.g. `-c web_search="live"`). Lanes that call some MCP disable the rest surgically — `-c 'mcp_servers.<name>.enabled=false'`, required servers first. `-c 'mcp_servers={}'` is a NO-OP — table overrides deep-merge, the fleet still spawns. But a codex lane cannot CALL an external MCP tool at all: `codex exec` runs at `approval: never`, so an approval-gated tool call is cancelled mid-flight and the model may fabricate a result instead of surfacing it (the codex skill's MCP-selection section carries the proof). A lane's callable tools are the model's reasoning, sandboxed shell, `web_search`, and file ops — design lanes around those; when a step must invoke an MCP tool, keep it in a Claude `agent()` (native fleet), never a codex lane.

## [05]-[RECEIPT]

The receipt is MECHANICAL. On READY the harvester never relays the report body: it jq-counts the product's primary array for `entries` and jq-builds `headline` (per-class/kind tallies, top file) — never its own judgment or a lifted summary sentence — so the terminal reader meets every product cold. Failure lives in the envelope (`ok: false` + `failure` = the stderr tail or `turn.failed` message in one line), never as sentinel values inside data rows. Codex tokens are invisible to `budget.spent()` — budget-gated loops meter only their Claude lanes; `turn.completed.usage` summed across lanes' events files is the fleet's own token ledger. The receipt-and-roster contract, the product schemas, and the terminal reader's consumption protocol are the report-file pattern in the patterns reference.
