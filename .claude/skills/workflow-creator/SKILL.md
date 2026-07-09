---
name: workflow-creator
allowed-tools: Bash(node ${CLAUDE_SKILL_DIR}/scripts/*)
description: >-
  Author runnable workflow scripts for Claude Code's Workflow tool — deterministic
  multi-agent orchestration files that fan out fresh-context subagents under plain
  JavaScript control flow. Use this skill whenever the user wants to create, write,
  build, scaffold, design, or fix a workflow: "make a workflow", "create a workflow
  for X", "write a workflow", "turn this into a workflow", "scaffold a multi-agent
  pipeline", "orchestrate this with subagents deterministically", or any request to
  author or edit a .js file under .claude/workflows/. Also use it when the user is
  confused about the workflow script format — the meta block, agent()/parallel()/
  pipeline()/phase(), schemas, the determinism rules — or when a workflow errors and
  needs debugging. Trigger this even when the user only describes a repeatable
  multi-step or parallel job and seems to want it packaged as a workflow, even if
  they never say the word "workflow". Do NOT use it to merely run an existing
  workflow, or for a one-off single-subagent task.
---

# Workflow Creator

Turn a goal into a **runnable workflow file** — a JavaScript orchestrator for Claude Code's `Workflow` tool.

A workflow fans work out to fresh-context subagents under **deterministic JavaScript** control flow: the loops, the conditionals, the fan-out are plain code, and only the leaf `agent()` calls spend model tokens. This skill owns the file format, the judgment calls, and the authoring procedure. Use it to write a new workflow, convert a multi-step job into one, or fix a broken script.

The deep material lives in two reference files, read in this order:

- `references/api-reference.md` — read **first**, the correctness source: the
  complete manual (every global, every option, every cap and constant, what
  happens at each limit) and the deep owner of the `pipeline` vs `parallel`
  decision.
- `references/patterns.md` — read **second**, the composed-topology catalog
  (fan-out, pipeline, routing, orchestrator-workers, evaluator-optimizer,
  adversarial verify, judge panel, nested workflow, report-file fan-out). Copy
  the topology that fits Step 2's answers.

Starter files are in `assets/templates/` — control-flow skeletons (fan-out, pipeline, loop) plus `run-ledger.template.md`, the resume ledger Step 7 requires. Complete, runnable example workflows are in `assets/examples/` — `assets/examples/README.md` maps each one to a topology and to the model / structured-output techniques it shows. A linter and a dry-run simulator are in `scripts/`.

## Hard rules — the six that break runs

1. `meta` is a **pure literal**, the first statement, **no backticks anywhere** inside it.
2. `Date.now()`, `Math.random()`, and argless `new Date()` **throw** — pass timestamps via `args`; vary "randomness" by loop index.
3. No filesystem or Node APIs in the orchestrator — file and shell work lives **inside `agent()`**; the body is plain JavaScript, never TypeScript.
4. `parallel()` takes **thunks** (`[() => agent(…)]`), never bare promises.
5. Always `.filter(Boolean)` on `parallel()`/`pipeline()` results — skipped, failed, and budget-dropped items are `null` holes.
6. A heavy lane product (a map, findings set, dossier — anything past ~50 rows) goes to **disk**; only the thin receipt `{ok, report, entries, headline, failure}` crosses the wire, and the terminal reader reads every ok report file IN FULL. Relaying a product through an intermediate agent's output truncates it silently (Step 4 "Data flow"; `references/patterns.md` §21 is the runnable shape).

The Gotchas section at the bottom carries the full list with rationale.

---

## Stop & resume a run without losing work — read this first

A run is a background task you pause, stop, and resume from `/workflows`, and **completed work is never lost**: every agent's result is journaled the instant it finishes, so a pause or stop only ever discards agents still in flight, which re-run on resume.

- **Pause / resume:** `p` in `/workflows` toggles a pause — the gentle hold, nothing discarded.
- **Stop:** `x` (with focus on the run) stops the whole run; `TaskStop` does it programmatically. Completed agents stay cached; only in-flight agents drop. Use `r` to restart one stuck agent without stopping the run.
- **Resume:** `p` in `/workflows`, or relaunch with `Workflow({ scriptPath, resumeFromRunId })` — completed agents return cached results, the rest run live. **A bare `Workflow({ scriptPath })` or `Workflow({ name })` is NOT a resume** — with no `resumeFromRunId` it is a brand-new run from zero. Stop a still-running prior run before relaunching.
- **Same session only — with one escape hatch.** A plain resume works solely in the session that launched the run; from a new session it finds an empty journal and re-runs from zero. The journal itself is content-addressed and portable: transplant it into the new session's run directory and resume (`references/api-reference.md` §11, cross-session journal transplant). Even if the run ID has left your context, recover it in-session from `/workflows` or the `wf_<id>` run-directory name.

Capture the run ID the moment the run starts (Step 7), and do not edit the launched script while it is resumable. The journal mechanism and the precise restart causes are `references/api-reference.md` §11.

---

## Step 0 — Where workflows live

Workflow files live in `.claude/workflows/<name>.js` (project-local) or `~/.claude/workflows/<name>.js` (global). The filename is not the workflow name — the `name` inside the `meta` block is. The tool is enabled by default — write the file and it runs.

---

## Step 1 — Decide whether a workflow is even the right tool

Do not reach for a workflow by default — it is the heaviest option and it is gated for a reason (it can spend a lot of tokens). Pick deliberately:

| The job | Right tool |
|---|---|
| One subagent, one task | The plain **`Agent`** tool — no workflow |
| A reusable procedure where **Claude** picks the steps each run | A **Skill** |
| Many subagents in a **fixed** shape (fan-out / pipeline / loop), same every run, worth resuming | A **Workflow** ✅ |

A workflow earns its cost when **all** of these are true: the work is parallel or multi-stage; you want the orchestration deterministic and resumable; and isolating each step in its own fresh context window is an advantage. If you are unsure, say so and offer the lighter option instead.

---

## Step 2 — Find the shape of the job

Before writing a line of code, answer these. The answers pick the topology for you.

1. **What is the unit of work?** The thing one subagent does once — review one file, research one question, draft one platform. Name it concretely.
2. **How many units, and is the count known up front?** A known list → map over it. An unknown count (discovery, "find all the bugs") → a loop.
3. **What is the topology?**
- Independent units, one pass each → **fan-out**.
- Units flow through ordered stages (review → verify) → **pipeline**.
- Keep going until a target count or a budget runs low → **loop**.
4. **Does any later step need *all* the earlier results at once** — to dedup, merge, count, or early-exit on a zero total? If yes, you need a **barrier**. If no, you do not — and you should prefer `pipeline`.
- **The deferral case.** If a unit DEFERS work it cannot do alone (cross-item, cross-file, "report and move on"), a fan-out is not enough — add a terminal reconcile stage that consumes the collected deferrals, or they reach the conversation and nothing acts on them. Structure each deferral as DATA whose resource slot is a LIST (`{files: string[], claim}`) so a deferral spanning two files names BOTH — that is what lets you cluster deferrals by shared resource in plain JS, then fix-and-verify each cluster (pattern #13). A single-resource slot can only group same-resource items and silently cannot express a cross-item seam.
5. **Does a step need structured data back** (not free text)? Then that `agent()` call needs a `schema`.

Write these five answers down for the user before coding. They are the design.

**Terminal stages are opt-in, not a default.** A reconcile / collapse / align stage exists only when the work needs it — workers deferred cross-item fixes (the deferral case above, pattern #13), or a later pass must hold the whole corpus to unify it. A pure fan-out or a pure refinement workflow legitimately ends at its last per-item stage with no terminal stage at all; do not bolt one on out of habit, and do not assume the discover → work → reconcile → collapse shape is the canonical mold. When a workflow is

**parameterized by a target** (a file, a sub-folder at any depth, a unit root, or several at once), resolve the scope with the discovery-agent shape in `references/patterns.md` #19 — expand targets inside an agent (the orchestrator has no filesystem), keep the targeted subset (the cost lever) separate from the folder-wide blast radius, and read `args` as `string | array | {targets}` with a no-op default.

---

## Step 3 — The decision that matters most: `pipeline` vs `parallel`

This is the call people get wrong, so make it explicitly.

- **`pipeline(items, stage1, stage2, …)` is the default for multi-stage work.** Each item flows through every stage on its own — **there is no barrier between stages**. Item A can be in stage 3 while item B is still in stage 1. Wall-clock = the slowest single item's whole chain, not the sum of the slowest stage at each step.
- **`parallel(thunks)` is a barrier.** It waits for every task before returning. Reach for it **only** when a stage genuinely needs the *entire* previous result set in hand — dedup across all findings, merge, a count-based early-exit. "It is cleaner code" or "the stages feel separate" are **not** reasons — a pipeline models separate stages fine.

Smell test: if you would write `const a = await parallel(...)`, then a plain transform (`flat`/`map`/`filter`) with no cross-item dependency, then another `parallel(...)` — that middle transform does not need the barrier. Make it a pipeline stage instead. **When in doubt, `pipeline`.**

---

## Step 4 — Write the file

A workflow file has exactly two parts, in this order. The parser is strict.

### Part 1 — the `meta` block (must be the very first statement)

```js
export const meta = {
  name: 'review-changes',                                   // required, non-empty
  description: 'Review changed files, verify each finding', // required — shown in the permission dialog
  whenToUse: 'Before shipping a branch',                    // optional — shown in the workflow list
  phases: [                                                 // optional — one entry per phase() call
    { title: 'Review' },
    { title: 'Verify', model: 'sonnet' },
  ],
}
```

`meta` **must be a pure literal** — no variables, function calls, spreads, or template strings inside it. Build dynamic values in the body, never in `meta`. Use the same phase `title` strings in `meta.phases` as in your `phase()` calls.

### Part 2 — the body (async JavaScript)

Everything after `meta` is the body. It runs inside an `async` function, so you `await` at the top level. These globals are injected — **do not import anything**:

| Global | Purpose |
|---|---|
| `agent(prompt, opts?)` | Spawn one fresh-context subagent. Returns its final text, or a validated object if `opts.schema` is set. Returns `null` if the user skips it. |
| `pipeline(items, s1, s2, …)` | Run each item through all stages, no barrier between stages. The default for multi-stage work. |
| `parallel(thunks)` | Run an array of **functions** `() => Promise` concurrently. A barrier. |
| `phase(title)` | Group the agents that follow under a heading in `/workflows`. |
| `log(msg)` | Emit a narrator line above the progress tree. |
| `console` | A standard-looking `console` — its output is routed into the workflow log. |
| `budget` | `{ total, spent(), remaining() }` — token target for budget-aware loops. |
| `args` | Whatever was passed as the Workflow tool's `args` input, exposed as **structured data** — an object/array/string you read directly (`args.minUsers`, `args.map(...)`). `undefined` if nothing was passed. Default the omitted case (see below). |
| `workflow(name, args?)` | Run another workflow inline. One level of nesting only. |

The body's `return` value becomes the tool result handed back to Claude.

> **`args` arrives as structured data — read it directly, never `JSON.parse` it,
> and default the no-args run.** An object stays an object, an array stays an
> array, a string stays a string; `undefined` when nothing was passed.
> `references/api-reference.md` §4 is the full map from each caller input to the
> exact `args` value, with the shape-check idioms.

### Long prompt strings — wrap with adjacent `+`, keep the value identical

Prompts are the bulk of a workflow and grow long. Keep source lines to ~150 columns by splitting one string across lines with adjacent `+` concatenation — JavaScript folds adjacent string operands into one value, so it stays **one string** with one value:

```js
const PROMPT =
  'TASK: realize the open cards of `' + folder + '` into design fences ' +
  'at the doctrine bar. Read each card body, the pages it seams to, and ' +
  'verify every novel member before you write.'
```

- Break **at a space**, and keep that space on the left segment (`'…fences '`). Drop it and two words fuse — a silent prompt change.
- Never "wrap" with a multi-line template literal: real newlines inject `\n` into the value, changing what the agent reads *and* the resume-cache key. `+` concatenation changes the source only, never the value.
- Body prompts only. **Never wrap inside `meta`** — it must stay a pure literal (a stray `+` or backtick there fails the linter); a long `meta.description` stays one line.

### The three `agent()` opts you tune most — `model`, `effort`, `schema`

Three independent axes set per `agent()` call; `references/api-reference.md` §5 is the full table of each, with the alias resolver, the validation rules, and the resume-cache-key membership.

- **`model`** picks the model for that call (`'sonnet'`/`'opus'`/`'fable'`/`'inherit'` or a full ID — `'sonnet'` is the floor). Drop cheap, high-volume, mechanical leaf work to `'sonnet'`, or route a self-contained lane to gpt-5.5 through the codex wrapper below; leave judgement-heavy work on the inherited model. The matching `meta.phases[].model` is a **dialog label only** — set both for a re-tiered phase or the dialog lies.
- **`effort`** tiers the reasoning (`'low'`…`'max'`), independent of `model`: `'max'`/`'xhigh'` for synthesis and adversarial judgment, `'low'` for mechanical leaf work. A cheap model can still reason hard.
- **`schema`** (a JSON Schema) forces a **validated object** back instead of a string — pass it for any result a later line reads a field off of, keep it small and `required`-tight. To hand data between stages, `JSON.stringify` it into the next prompt; the orchestrator shares no memory with the subagent.

### Dispatching gpt-5.5 (Codex) — the wrapper shape

`model` accepts only Claude models, so a self-contained codex lane (repo sweep, audit, research, or a mechanical edit) routes through a thin wrapper agent whose ONLY job is **dispatch-and-receipt**: `model: 'sonnet', effort: 'low'`, label prefixed `gpt-5.5:`. The wrapper writes the task and the product schema to run scratch with the Write tool, launches codex detached, polls the `-o` report by liveness, and returns the thin RECEIPT — the product stays on disk for the terminal reader. It never performs, edits, judges, softens, summarizes, or relays the work itself. The task file is the quoting-proof prompt channel (`codex exec … "Do the task in <task>.md"` — long prompts through shell argv are the fragility); the `--output-schema` file is what makes codex's report typed JSON.

```js
// TWO schemas: codex gets the PRODUCT schema (via the --output-schema file); the wrapper's
// own schema is the thin RECEIPT — the product body never crosses the wire.
// The wrapper is LAUNCH-ONLY: it returns a launch receipt in seconds; the orchestrator's
// setTimeout harvest loop (bullet below) owns the waiting and the promotion.
const receipt = await agent(codexPrompt('audit-auth', task, PRODUCT_SCHEMA, /*writes*/ false),
  { model: 'sonnet', effort: 'low', label: 'gpt-5.5:audit-auth', schema: RECEIPT })
```

- **Sandbox = modality.** `-s read-only` for investigation/research/response lanes; `-s workspace-write` when codex must author or edit files (partition write scopes across concurrent wrappers, or keep codex read-only and let a Claude writer apply edits — two workspace-write runs over one path collide). Set `-s` explicitly; the config default is not read-only.
- **Wrappers never wait — launch receipt + orchestrator harvest loop.** A wrapper agent has no legal wait primitive: subagent Bash blocks foreground `sleep`, a blocking `until` loop dies with its one call, background Bash tasks never notify a workflow subagent, and idle no-op calls ("waiting" text, `sleep 1`, `true`) trip the runtime's no-progress enforcement — which force-returns the wrapper with a FALSE `ok:false` while codex runs on and the report lands with no promoter; `stallMs` does not license idling. So the wrapper's ONLY job is the launch, finished in seconds: purge stale artifacts, Write task/schema, launch codex DETACHED with a bare `&` (`… -o <report> "<prompt>" </dev/null >/dev/null 2><report>-stderr.log &` — never `nohup`; the stderr log's tail IS the crash reason when a run dies with no report), verify the process is alive (`pgrep -f "<report-basename>"`), and return the LAUNCH receipt `{ok:true, report:'', entries:0, headline:'launched', failure:''}`. TIME lives in the orchestrator: `await new Promise((r) => setTimeout(r, INTERVAL_MS))` between rounds (`setTimeout` is an injected workflow global), then one short-lived harvester agent per round that, for each pending lane, promotes a finished report mechanically (jq-validate, extract to the durable home, jq-count the receipt fields), marks a gone-process-with-no-report DEAD carrying the stderr tail, relaunches a DEAD lane at most once, and returns `{promoted, dead, pending}`; the loop exits when pending empties or a round cap fires. An absent report while the process is alive is NORMAL — the loop just waits another round; never relaunch a live run. A lane alive far past its expected wall (~20 min for a recon lane — concurrent lanes contend for the machine) is WEDGED: the harvester kills it (`pkill -f "<report-basename>"`) and treats it as DEAD. The harvester's checks are a PRE-STAGED SCRIPT — one launch wrapper writes `harvest.sh` (promote/alive/dead logic, exact pgrep patterns baked in) and every harvest round just executes it and relays its JSON verdict; prose-described check mechanics get re-derived by each round's fresh agent and eventually botched (empirical: a mis-expanded pgrep pattern declared four live lanes dead). A short synchronous leg (comfortably inside its tier timeout) needs none of this — one Bash call, stdout capture, no detach.
- **Disable MCP on fan-out lanes.** Every codex process spawns the full `~/.codex/config.toml` MCP server fleet as children — N concurrent lanes start N fleets, and one wedged server handshake leaves codex alive-but-idle forever. File-only lanes pass `--ignore-user-config` (config.toml skipped wholesale — no fleet, no notify hook; auth and the gpt-5.5/medium defaults survive; restate needed config as flags, e.g. `-c web_search="live"`). `-c 'mcp_servers={}'` is a NO-OP — table overrides deep-merge, the fleet still spawns; surgical single-server removal is `-c 'mcp_servers.<name>.enabled=false'`. Keep the fleet only when the task genuinely calls MCP tools.
- `</dev/null` is non-negotiable — `codex exec` blocks forever on open stdin; the stderr banner `Reading additional input from stdin...` prints even under `</dev/null` and is not a hang. Stderr goes to the lane's `stderr.log` per the scratch convention, never a sink — a silent crash with no log is undiagnosable. Two startup stderr lines are noise, never a crash reason: an rmcp `AuthRequired` fatal for any OAuth MCP server not logged in (fires whenever the fleet spawns), and a system-skills reinstall race (`Directory not empty (os error 66)`) under concurrent lane launches. `--ephemeral` suits fan-out lanes that never resume.
- **Schemas are STRICT and files are Write-tool-written.** codex's `--output-schema` runs the OpenAI strict profile — the stricter row of the validator split in `references/api-reference.md` §5; design conditional fields as required-but-empty (`""`/`[]`). The wrapper writes the task and schema files with the Write tool at ABSOLUTE paths under the repo root (never a shell heredoc — cwd drift and quoting land files where codex cannot find them) and the launch call verifies both with `test -s` before starting codex.
- **The receipt is MECHANICAL.** On READY the wrapper never relays the report body: it jq-counts the product's primary array for `entries` and jq-builds `headline` (per-class/kind tallies, top file) — never its own judgment or a lifted summary sentence — so the terminal reader meets every product cold. Codex tokens are invisible to `budget.spent()` — budget-gated loops meter only their Claude lanes. The full dispatch mechanics live in the `codex` skill; `references/patterns.md` §21 is the workflow-level composition.

### Data flow between stages — products on disk, receipts on the wire

Vocabulary first, one meaning each: a LANE is one concurrent worker in a fan — its own scope, product, and receipt; a STAGE is one position in a pipeline; a PRODUCT is a lane's complete output; a RECEIPT is the thin `{ok, report, entries, headline, failure}` envelope that stands in for it on the wire. Three sourcing tiers, chosen by product size — never mixed ad hoc:

1. **Inline structured output** — small structural outputs (plans, slices, verdicts, counts, paths): schema-tight through `agent()` structured output. The default below ~50 rows.
2. **Scratch product file** — any heavy product (maps, findings, dossiers, reports): the producing lane WRITES the complete product to a deterministic path under run scratch and returns only the receipt `{ok, report, entries, headline, failure}`. Consumers READ THE FILE IN FULL from disk — never a re-serialized copy: every relay hop through an intermediate agent's structured output is a truncation/paraphrase risk on the weakest model in the chain, and `JSON.stringify` of a full product into a downstream prompt is a smell past ~50 entries — context spent before the work starts.
3. **`journal.jsonl`** — recovery-only. Never a designed data path.

Laws that ride the pattern (`references/patterns.md` §21 carries the runnable shape, the product schemas, and the terminal reader's consumption protocol):
- Failure lives in the ENVELOPE (`ok: false` + `failure` = the stderr tail in one line), never as sentinel values inside data rows — no downstream agent string-matches magic values out of the data plane; downstream filters on `ok` alone.
- `headline` is MECHANICAL — jq tallies over the product's primary array, never the lane's own judgment — so the terminal reader meets every product cold, unanchored.
- `scope` is ORCHESTRATOR-OWNED: the dispatch helper's `.then()` attaches `scope: o.scope || []` to every roster row from what the orchestrator ASSIGNED at construction — never the lane's self-report — so a lane that dies before writing anything still names its territory exactly.
- The terminal reader's prompt carries the ROSTER (one `{lane, scope, ok, report, entries, headline, failure}` row per lane) plus the UNMAPPED queue — failed lanes' scopes flattened in plain JS — read UNMAPPED-first as its own cold hunt, then every ok report IN FULL.
- Codex lanes get tier 2 for free — `-o` already writes the report file; the wrapper counts with `jq` and returns the receipt, never the body.
- Recovery synergy: product files make every stage re-enterable at zero cache dependence (the continuation-script law) — receipts are exactly what a continuation script rebuilds.

**The scratch convention** — one layout, no exceptions:
- **Run scratch** is `.claude/scratch/<workflow-name>/` (repo-relative, gitignored, ephemeral — deletable once the run's campaign closes). ONE folder per workflow; never a tool-segregated dir (no `codex/`), never a bespoke `<name>-grounding` sibling. Scope (campaign/target slug) rides the FILENAME, not extra nesting.
- **Gitignore consequence**: `rg`/`fd`/Grep skip ignored dirs by default, so consumers are handed EXPLICIT paths (the roster) and read them directly — never asked to discover products by search. An agent that must hunt inside scratch passes `--no-ignore` (rg) or `-I` (fd).
- **File grammar**: `<scope>-<lane>-<artifact>.<ext>` — lane is a 1-2 word semantic slug (`s0`, `gov`, `rip-python`, `dossier`, `ledger`), artifact names the role (`task`, `schema`, `report`, `stderr`). No agent names, no timestamps, no run IDs in filenames.
- **Codex lanes own exactly four artifacts**, each forced by the CLI interface: `task.md` (the quoting-proof prompt channel — long prompts through shell argv are the fragility), `schema.json` (`--output-schema` accepts only a file path), `report.json` (a detached run needs `-o`), `stderr.log` (the crash reason). Do not invent more; do not merge them.
- **Stale purge is law**: a lane's first act deletes its own prior `report`/`stderr` (`rm -f`) — a leftover report satisfies the poll instantly and returns LAST run's data.
- **Legacy paths are history**: report specimens under `.claude/scratch/codex/` are read-only evidence of retired runs, never a copy target — every new lane writes under its own workflow's run scratch.
- **Vocabulary**: run scratch (above, the lanes' data plane — codex sandboxes can write it) is distinct from the SESSION SCRATCHPAD (the harness temp dir outside the repo) — orchestrator-only artifacts like the run ledger live in the session scratchpad, never in run scratch.

For full signatures, every option, and every cap, **read `references/api-reference.md` now.** For ready-made orchestration shapes, **read `references/patterns.md`** and copy the one that fits Step 2's answers. Or start from a file in `assets/templates/`, or adapt a full worked example from `assets/examples/` (its `README.md` says which one fits).

---

### File organization — canonical sections

A workflow reads top-to-bottom as the `meta` manifest, then the body in this fixed section order (omit any a file doesn't need). Mark each with a `[08]`-grammar divider `// --- [LABEL]` plus dash-fill, never free text after the bracket:

```
// --- [CONSTANTS] -----------------------------------------------------------------------
// dependency-free knobs: CAP, BATCH, STALL, caps, static tier/config tables (group the concurrency knobs)

// --- [INPUTS] --------------------------------------------------------------------------
// args read + derived scope/target/root (depends on the args global)

// --- [MODELS] --------------------------------------------------------------------------
// JSON Schemas for structured agent output

// --- [DOCTRINE] ------------------------------------------------------------------------
// shared prompt-law TEXT consts woven into prompts; a composed DOCTRINE const comes LAST, after the blocks it joins

// --- [OPERATIONS] ----------------------------------------------------------------------
// pure helpers: the pool/sleep harness, clustering, prompt builders, dispatch tables (a STAGES table over the builders lives here, after them)

// --- [COMPOSITION] ---------------------------------------------------------------------
// the run: phase()/agent()/pipeline()/parallel()/log() + reshaping + the final return

// --- [SUB_SECTION_STYLE]
```

Inside a long `[COMPOSITION]`, mark each phase with a **bare** subsection divider whose label is the `phase()` title in UPPER_SNAKE (`// --- [RECONCILE]`, no fill).

Rules that bite:
- Knobs (`CAP`/`BATCH`/`STALL`) go in `[CONSTANTS]` at the top, never buried in the pool block.
- args-derived values are `[INPUTS]`, never `[CONSTANTS]` — they depend on the runtime `args`.
- A const that references a function or a later value is not a `[CONSTANTS]`: a dispatch table over the prompt builders is `[OPERATIONS]` after them; a composed `DOCTRINE` const follows the blocks it joins. An input derived through a helper co-locates that helper in `[INPUTS]`.
- Banned drift labels: `[HARNESS]` `[SCHEMAS]` `[LAW]` `[CONFIG]` `[PROMPTS]` `[HELPERS]` `[FOLDER]` `[SCOPE]` and singular `[INPUT]`. Use the canonical label.
- A packer that consolidates heterogeneous clusters into a bounded agent count balances by WORK WEIGHT (distinct files dominate an agent's load), never item count, and caps cluster atomicity at the FAIR SHARE (`totalWork / n`): an over-budget connected component sub-shards file-atomically (same-lead-file rows never split; the verify stage owns the deliberate cross-shard seams; shard prompts carry the anchored-Edit collision discipline), and per-bucket weights are logged — the full law is patterns.md §13 "Bounded buckets". Applies equally to pool-per-cluster shapes (`cap = totalWork / POOL_CAP`). Uniform `chunk(pages, N)` batches are exempt.

## Step 5 — Validate and dry-run before running

Two bundled checks gate every workflow before it spends a token. Run both; reach for an external parser for neither.

First the linter — the parser's hard rules:

```bash
node ${CLAUDE_SKILL_DIR}/scripts/validate-workflow.mjs <file.js>
```

A missing or non-first `meta`, a non-literal `meta` (a stray backtick included), a missing `name`/`description`, a banned non-deterministic call, and an oversized script are ERRORS — exit 1, fix every one. An `effort`/`model` value outside the allowed set, a host API, and a bare-promise `parallel([agent(...)])` are WARNINGS — exit 0, but each is a real runtime bug, so clear them too. The linter checks rules, not syntax — it will not catch an unbalanced paren.

Then dry-run it — the syntax, control-flow, and determinism check, for zero tokens:

```bash
node ${CLAUDE_SKILL_DIR}/scripts/dry-run.mjs <file.js> [--args '<json>'] [--fixtures '<json>']
```

It re-hosts the unmodified file under mocked globals, runs the real control flow with `agent()` returning fixtures, and runs twice to prove determinism. Read the report (patterns reference §16 has the full signal list):
- `parseOk=true ran=true deterministic=true` is the gate; anything else is a bug and exits non-zero.
- `perPhase` / `totalAgents` — a phase spawning far more than you expect is a fan-out bug; a phase MISSING from the sequence means an `if (!x)` guard dropped the minimal fixture, so feed real shapes with `--fixtures` keyed by agent label.
- `maxConcurrentObserved` and cap warnings — past 16 concurrent the runtime queues the excess (a warning, not a refusal), but past the 1000-agent lifetime total the runtime throws, so treat that warning as a real bug.

Counts are REPRESENTATIVE, not exact production — fixtures are minimal by design. A green dry-run validates the machine, not the meaning: it cannot judge prompt quality, a schema's `required` set, or the effort tier. For that, do a NARROW real run on one tiny scope (§16) — `dry-run.mjs --mode real --scope <path>` prints the exact `Workflow(…)` invocation for you to authorize and spawns nothing.

Do not rely on raw `node --check`: a workflow body's top-level `return` and `export const meta` parse under no single module mode, so it rejects a valid file either way. The linter and the dry-run are the dependable checks.

### Skill-level regression — `evals/evals.json`

The two scripts gate each **authored workflow**; `evals/evals.json` gates **this skill**: behavioral cases (explicit, implicit, and debugging triggers, plus must-NOT-trigger controls) whose `expected_behavior` assertions use the linter and dry-run as deterministic graders. Re-run them after editing the frontmatter `description` or the Hard rules, and after a Claude Code or model bump — execute each `query` in a fresh session and check every assertion; the skill-creator plugin's eval loop automates the runs and measures trigger rate. A case that passes with the skill disabled is teaching nothing — replace it.

---

## Step 6 — Run, watch, iterate

Run a named workflow with `Workflow({ name: 'review-changes' })`, or a file with `Workflow({ scriptPath: '…' })`. It runs in the **background** — the call returns a run ID immediately and a `<task-notification>` arrives on completion. Watch it live with the `/workflows` command and drill into any agent mid-run; the safe way to stop, pause, and resume it is the **Stop & resume** section at the top of this skill.

A user reaches a workflow from their side in three ways: a saved or bundled command (`/deep-research …`, or any workflow saved to `.claude/workflows/`); the `ultracode` keyword in a prompt (or asking "use a workflow" in plain words), which makes Claude write a one-off workflow for that task; or `/effort ultracode`, which lets Claude plan a workflow for every substantive task in the session. Saving a good run is `s` in `/workflows`, which writes the script to `.claude/workflows/` (project) or `~/.claude/workflows/` (personal) as a reusable `/<name>` command.

To iterate during authoring, **edit the saved file** and resume it (see **Stop & resume** above): every `agent()` call before your first edit replays from cache, and only the changed call onward re-runs. Never re-paste the whole script after the first run — edit the file.

---

## Step 7 — Capture a run ledger for safe resume (required)

The **Stop & resume** section above is the procedure; this step is the one habit that makes it reliable. The moment `Workflow` returns, record a **run ledger**: a small file (in the session scratchpad, never the repo) holding the run ID, the launched `scriptPath`, the `args`/scope, and the exact `Workflow({ scriptPath, resumeFromRunId })` command. Copy `assets/templates/run-ledger.template.md` and update it on every resume or restart. Without the captured run ID a later turn cannot resume — it can only start over.

The ledger is **not** the journal. The journal (`journal.jsonl`, written automatically by the runtime in the run directory) is the cache of agent results that *does* the resuming; the ledger is your one-line note of the run ID needed to *trigger* a resume. You write the ledger; the runtime writes the journal. Lose the run ID and the journal is still on disk, but no later turn knows which run to resume — so it starts over.

The ledger is only useful if a later turn does not silently invalidate the cache, so it also records the cache-invalidation rules that keep a resume from silently re-running work:

- **`schema`, `model`, `isolation`, and `agentType` are the resume cache key** (full table in `references/api-reference.md` §5), and the prompt text is hashed into it too. Change any of them — or the `args` that feed a prompt — and that call and everything after it re-runs live. `label`, `phase`, `effort`, and `stallMs` are **not** in the key; tune them freely.
- **Do not edit the launched script while the run is resumable** — any cache-key change re-runs that call onward. Edit only when you *intend* to re-run from that point (the Step 6 loop).
- **Launch from a stable on-disk `scriptPath`**, so the exact bytes that ran stay on disk to replay against; an inline `script` string leaves nothing stable to resume from.

---

## Gotchas — check every one before you hand over the file

These are the mistakes that actually break workflows:

- **Determinism bans.** `Date.now()`, `Math.random()`, and argless `new Date()` **throw** inside a workflow — they would break resume. Pass timestamps in via `args` and stamp results *after* the workflow returns; vary "randomness" by loop index instead. `new Date(specificValue)` is fine.
- **No filesystem, no Node APIs** in the orchestrator. No `require`, `fs`, `process`. Any file read/write/Bash work belongs **inside an `agent()`** — the subagent has the normal tools; the orchestrator does not.
- **No agent idles — waiting is orchestration.** An agent that waits on anything external (a detached process, another lane, a file appearing) is a design error: subagent Bash blocks foreground `sleep`, background tasks never notify a workflow subagent, and idle no-op calls trip no-progress enforcement into a forced FALSE return — `stallMs` does not license idling. Restructure every "wait" as: agent launches and returns a receipt → the orchestrator holds time (`await new Promise(r => setTimeout(r, ms))` — the one legal clock) → a fresh short-lived agent runs the next check round.
- **Repeated mechanics are staged artifacts, not prose.** Any step executed more than once across rounds or lanes (checks, promotions, validations) is written ONCE as an executable script and executed verbatim thereafter. Each fresh agent re-deriving mechanics from prose is an independent chance to botch them; across N rounds a botch is guaranteed (empirical: one round's mis-expanded pgrep declared four live lanes dead).
- **Receipts are claims; disk artifacts are truth.** An agent's failure report is not ground truth: before re-running or discarding a lane, check its deterministic artifact paths — product file present and valid, process liveness, stderr tail. Forced returns file false failures while the real work completes; a stale leftover artifact reads as false success (hence the stale-purge law). Design every lane so its truth is checkable from disk alone, and reconcile the roster against disk before acting on it.
- **`parallel()` takes thunks, not promises.** It must be `[() => agent(...), () => agent(...)]`, never `[agent(...), agent(...)]`. Bare calls start immediately and defeat the concurrency limiter.
- **A `pipeline()` stage callback gets `(prevResult, originalItem, index)`.** A stage that takes only `prevResult` cannot label or scope by the source item — it loses the `originalItem`/`index` it needs to name `verify:${file}` or branch on position, and silently mislabels or mis-scopes. Take all three params in any stage past the first: ``(review, file, i) => agent(…, { label: `verify:${i}` })``.
- **Always `.filter(Boolean)`.** `parallel()` and `pipeline()` put `null` in the slot of any item that threw, was skipped, or was dropped by the budget. The result arrays have holes by design.
- **`meta` is a pure literal and the first statement.** No dynamic values, no code before it.
- **Open-ended loops need a hard stop** — a counter (`while (found < 10)`) or a budget guard (`while (budget.total && budget.remaining() > 50_000)`). With no budget set, `budget.remaining()` is `Infinity`; an unguarded loop sprints into the 1000-agent lifetime cap and throws.
- **A fix→verify drive-to-zero loop gates on PROGRESS, not just the round cap.** When a loop re-queues the residuals a verify left open and re-verifies them round after round, the cap alone lets it burn every round confirming nothing. Three guards, all required: (1) skip the verify when the fix changed no file (or returned a `clean`/no-op verdict) — a fix that touched nothing has nothing to verify, so resolve-or-drop its residuals without spending one; (2) re-queue only genuinely-NEW residuals via a cumulative `seen` set keyed `sorted-files|claim`, so a fixer that re-surfaces the same item cannot re-feed the loop forever; (3) break the moment a round changes no file — the remainder is unfixable, so log + return it and stop. The cap is a runaway backstop, never the exit; the no-defer guarantee survives because a genuinely-open residual is still surfaced. The worked law is `references/patterns.md` §13.
- **`isolation: 'worktree'` is expensive** (~200–500 ms + disk per agent). Use it only when parallel agents mutate files and would otherwise collide.
- **Launch same-script Workflow runs one call at a time.** Empirical: three parallel Workflow invocations of one scriptPath in a single batch delivered args to two runs and empty args to the third, which failed its own validation and skipped. Launch same-scriptPath runs sequentially; an early `if (!required) return { skipped, reason }` guard makes the failure a 6ms no-op instead of a silent mis-run.
- **A launch into territory adjacent to a LIVE writer carries a seam law.** When a new agent's territory shares a file with an agent still running — or with that agent's uncommitted output — the new agent's prompt must name the foreign content FROZEN (never edit, move, or reformat it), sequence the shared file LAST with a mandatory full re-read immediately before the first edit, and restrict that file to surgical Edit operations — one full-file Write clobbers the sibling. A sibling's territory breach observed mid-flight is adjudicated at its receipt, never by intervening in a live run.
- **Grant permissions before a long parallel run.** Subagents run in `acceptEdits` mode and inherit the session tool allowlist; a non-allowlisted shell, web, or MCP call can still surface a mid-run permission prompt and stall the run.
- **Fence untrusted content an agent reads.** When an `agent()` processes attacker-influenceable input — a fetched page, a third-party doc, a user-supplied string, source of unknown origin — prefix it with a policy that names the content as DATA and wrap the text in an explicit fence, so instruction-shaped text inside it is not obeyed (`references/patterns.md` §18). A workflow over only trusted in-repo material does not need this.
- **The body is JavaScript only.** TypeScript syntax — type annotations, interfaces, `as` casts — is a parse error.
- **Read `args` as structured data and default the no-op.** `args` is the live value the caller passed (`string` / `array` / `object`), never JSON text — `JSON.parse(args)` throws on a non-string and corrupts an object. Branch on shape (`Array.isArray`, `typeof`, `args?.field`) and default the no-args run to a safe no-op, never a silent full-corpus sweep. ONE narrow carve-out exists for saved-command JSON-looking strings — the guarded `[INPUTS]` normalizer in `references/api-reference.md` §4; a bare `JSON.parse(args)` anywhere else stays forbidden. A saved workflow receives `args` via `Workflow({ scriptPath, args })`; if a build ever drops it for a `scriptPath` launch, relaunch with an inline `script` or encode the scope in the file (patterns #19).
- **Wrap long prompt strings with adjacent `+`, not a multi-line template.** Split at a space and keep the space on the left segment; the value must stay byte-identical — a fused word or an injected `\n` is a silent prompt change. Body prompts only, never inside `meta`. The linter warns once a single string literal runs past 160 chars.
- **No backticks anywhere in `meta`.** The linter reads any backtick inside the `meta` literal — even one inside a quoted string — as a template literal and rejects the file. Write identifiers in `name`/`description`/`phases` as plain text.
- **Call a nested `workflow()` once with the whole work-set, not per item in a loop.** Per-item calls don't share the child's cache or closure, so overlapping discovery is redone per item and an item primary in one call is mis-classified as secondary in another. Pass the full set in one call (patterns reference §15).
- **Key orchestration maps by a compound `owner|id`, not a bare id, when the id is not globally unique.** If the same logical id recurs under different owners (a mirrored/counterpart record reusing a slug across groups), a bare-id map silently merges across owners and corrupts the data; a composed key such as `owner + '|' + id` keeps them distinct.
- **Mark derived state on the branch that actually contributes, not before the guard.** `set.add(x)` placed *above* an `if (!keep) continue` over-reports `x` as a contributor even when it is skipped; move the `add` inside the keeping branch so the set mirrors what was really used.

---

## Worked example

For a complete runnable workflow — fan out one reviewer per dimension, then verify each finding the moment its review lands — read `assets/examples/review-branch.js` It is the canonical `pipeline` + nested `parallel` shape, with structured `schema` on every stage and an independently-tiered `model: 'sonnet'` / `effort: 'high'` verify stage. `references/patterns.md` §3 is the same shape stripped to its core.
