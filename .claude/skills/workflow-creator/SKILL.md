---
name: workflow-creator
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

Turn a goal into a **runnable workflow file** — a JavaScript orchestrator for
Claude Code's `Workflow` tool.

A workflow fans work out to fresh-context subagents under **deterministic
JavaScript** control flow: the loops, the conditionals, the fan-out are plain
code, and only the leaf `agent()` calls spend model tokens. This skill owns the
file format, the judgment calls, and the authoring procedure. Use it to write a
new workflow, convert a multi-step job into one, or fix a broken script.

The deep material lives in two reference files, read in this order:

- `references/api-reference.md` — read **first**, the correctness source: the
  complete manual (every global, every option, every cap and constant, what
  happens at each limit) and the deep owner of the `pipeline` vs `parallel`
  decision.
- `references/patterns.md` — read **second**, the composed-topology catalog
  (fan-out, pipeline, routing, orchestrator-workers, evaluator-optimizer,
  adversarial verify, judge panel, nested workflow). Copy the topology that fits
  Step 2's answers.

Starter files are in `assets/templates/` — control-flow skeletons (fan-out,
pipeline, loop) plus `run-ledger.template.md`, the resume ledger Step 7 requires.
Complete, runnable example workflows are in `assets/examples/` —
`assets/examples/README.md` maps each one to a topology and to the model /
structured-output techniques it shows. A linter and a dry-run simulator are in
`scripts/`.

---

## Stop & resume a run without losing work — read this first

A run is a background task you pause, stop, and resume from `/workflows`, and **completed work
is never lost**: every agent's result is journaled the instant it finishes, so a pause or stop
only ever discards agents still in flight, which re-run on resume.

- **Pause / resume:** `p` in `/workflows` toggles a pause — the gentle hold, nothing discarded.
- **Stop:** `x` (with focus on the run) stops the whole run; `TaskStop` does it programmatically.
  Completed agents stay cached; only in-flight agents drop. Use `r` to restart one stuck agent
  without stopping the run.
- **Resume:** `p` in `/workflows`, or relaunch with `Workflow({ scriptPath, resumeFromRunId })` —
  completed agents return cached results, the rest run live. **A bare `Workflow({ scriptPath })`
  or `Workflow({ name })` is NOT a resume** — with no `resumeFromRunId` it is a brand-new run from
  zero. Stop a still-running prior run before relaunching.
- **Same session only.** Resume works solely in the session that launched the run; a new session
  (or one started after quitting Claude Code) starts fresh. Even if the run ID has left your
  context, recover it in-session from `/workflows` or the `wf_<id>` run-directory name.

Capture the run ID the moment the run starts (Step 7), and do not edit the launched script while
it is resumable. The journal mechanism and the precise restart causes are
`references/api-reference.md` §11.

---

## Step 0 — Where workflows live

Workflow files live in `.claude/workflows/<name>.js` (project-local) or
`~/.claude/workflows/<name>.js` (global). The filename is not the workflow name —
the `name` inside the `meta` block is. The tool is enabled by default — write the
file and it runs.

---

## Step 1 — Decide whether a workflow is even the right tool

Do not reach for a workflow by default — it is the heaviest option and it is
gated for a reason (it can spend a lot of tokens). Pick deliberately:

| The job | Right tool |
|---|---|
| One subagent, one task | The plain **`Agent`** tool — no workflow |
| A reusable procedure where **Claude** picks the steps each run | A **Skill** |
| Many subagents in a **fixed** shape (fan-out / pipeline / loop), same every run, worth resuming | A **Workflow** ✅ |

A workflow earns its cost when **all** of these are true: the work is parallel or
multi-stage; you want the orchestration deterministic and resumable; and
isolating each step in its own fresh context window is an advantage. If you are
unsure, say so and offer the lighter option instead.

---

## Step 2 — Find the shape of the job

Before writing a line of code, answer these. The answers pick the topology for you.

1. **What is the unit of work?** The thing one subagent does once — review one
   file, research one question, draft one platform. Name it concretely.
2. **How many units, and is the count known up front?** A known list → map over
   it. An unknown count (discovery, "find all the bugs") → a loop.
3. **What is the topology?**
   - Independent units, one pass each → **fan-out**.
   - Units flow through ordered stages (review → verify) → **pipeline**.
   - Keep going until a target count or a budget runs low → **loop**.
4. **Does any later step need *all* the earlier results at once** — to dedup,
   merge, count, or early-exit on a zero total? If yes, you need a **barrier**.
   If no, you do not — and you should prefer `pipeline`.
   - **The deferral case.** If a unit DEFERS work it cannot do alone (cross-item,
     cross-file, "report and move on"), a fan-out is not enough — add a terminal
     **reconcile** stage that consumes the collected deferrals, or they reach the
     conversation and nothing acts on them. Structure each deferral as DATA whose
     resource slot is a LIST (`{files: string[], claim}`) so a deferral spanning
     two files names BOTH — that is what lets you cluster deferrals by shared
     resource in plain JS, then fix-and-verify each cluster (pattern #13). A
     single-resource slot can only group same-resource items and silently cannot
     express a cross-item seam.
5. **Does a step need structured data back** (not free text)? Then that
   `agent()` call needs a `schema`.

Write these five answers down for the user before coding. They are the design.

---

## Step 3 — The decision that matters most: `pipeline` vs `parallel`

This is the call people get wrong, so make it explicitly.

- **`pipeline(items, stage1, stage2, …)` is the default for multi-stage work.**
  Each item flows through every stage on its own — **there is no barrier between
  stages**. Item A can be in stage 3 while item B is still in stage 1.
  Wall-clock = the slowest single item's whole chain, not the sum of the slowest
  stage at each step.

- **`parallel(thunks)` is a barrier.** It waits for every task before returning.
  Reach for it **only** when a stage genuinely needs the *entire* previous
  result set in hand — dedup across all findings, merge, a count-based
  early-exit. "It is cleaner code" or "the stages feel separate" are **not**
  reasons — a pipeline models separate stages fine.

Smell test: if you would write `const a = await parallel(...)`, then a plain
transform (`flat`/`map`/`filter`) with no cross-item dependency, then another
`parallel(...)` — that middle transform does not need the barrier. Make it a
pipeline stage instead. **When in doubt, `pipeline`.**

---

## Step 4 — Write the file

A workflow file has exactly two parts, in this order. The parser is strict.

### Part 1 — the `meta` block (must be the very first statement)

```js
export const meta = {
  name: 'review-changes',                         // required, non-empty
  description: 'Review changed files, verify each finding', // required — shown in the permission dialog
  whenToUse: 'Before shipping a branch',          // optional — shown in the workflow list
  phases: [                                       // optional — one entry per phase() call
    { title: 'Review' },
    { title: 'Verify', model: 'haiku' },
  ],
}
```

`meta` **must be a pure literal** — no variables, function calls, spreads, or
template strings inside it. Build dynamic values in the body, never in `meta`.
Use the same phase `title` strings in `meta.phases` as in your `phase()` calls.

### Part 2 — the body (async JavaScript)

Everything after `meta` is the body. It runs inside an `async` function, so you
`await` at the top level. These globals are injected — **do not import anything**:

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

### The three `agent()` opts you tune most — `model`, `effort`, `schema`

Three independent axes set per `agent()` call; `references/api-reference.md` §5 is
the full table of each, with the alias resolver, the validation rules, and the
resume-cache-key membership.

- **`model`** picks the model for that call (`'haiku'`/`'sonnet'`/`'opus'`/`'fable'`/`'inherit'`
  or a full ID). Drop cheap, high-volume, mechanical leaf work to `'haiku'`; leave
  judgement-heavy work on the inherited model. The matching `meta.phases[].model`
  is a **dialog label only** — set both for a Haiku phase or the dialog lies.
- **`effort`** tiers the reasoning (`'low'`…`'max'`), independent of `model`:
  `'max'`/`'xhigh'` for synthesis and adversarial judgment, `'low'` for mechanical
  leaf work. A cheap model can still reason hard.
- **`schema`** (a JSON Schema) forces a **validated object** back instead of a
  string — pass it for any result a later line reads a field off of, keep it small
  and `required`-tight. To hand data between stages, `JSON.stringify` it into the
  next prompt; the orchestrator shares no memory with the subagent.

For full signatures, every option, and every cap, **read
`references/api-reference.md` now.** For ready-made orchestration shapes, **read
`references/patterns.md`** and copy the one that fits Step 2's answers. Or start
from a file in `assets/templates/`, or adapt a full worked example from
`assets/examples/` (its `README.md` says which one fits).

---

## Step 5 — Validate and dry-run before running

Two bundled checks gate every workflow before it spends a token. Run both; reach for an
external parser for neither.

First the linter — the parser's hard rules:

```bash
node .claude/skills/workflow-creator/scripts/validate-workflow.mjs <file.js>
```

A missing or non-first `meta`, a non-literal `meta` (a stray backtick included), a
missing `name`/`description`, a banned non-deterministic call, and an oversized script
are ERRORS — exit 1, fix every one. An `effort`/`model` value outside the allowed set,
a host API, and a bare-promise `parallel([agent(...)])` are WARNINGS — exit 0, but each
is a real runtime bug, so clear them too. The linter checks rules, not syntax — it will
not catch an unbalanced paren.

Then dry-run it — the syntax, control-flow, and determinism check, for zero tokens:

```bash
node .claude/skills/workflow-creator/scripts/dry-run.mjs <file.js> [--args '<json>'] [--fixtures '<json>']
```

It re-hosts the unmodified file under mocked globals, runs the real control flow with
`agent()` returning fixtures, and runs twice to prove determinism. Read the report
(patterns reference §16 has the full signal list):
- `parseOk=true ran=true deterministic=true` is the gate; anything else is a bug and exits non-zero.
- `perPhase` / `totalAgents` — a phase spawning far more than you expect is a fan-out bug; a phase MISSING from the sequence means an `if (!x)` guard dropped the minimal fixture, so feed real shapes with `--fixtures` keyed by agent label.
- `maxConcurrentObserved` and cap warnings — past 16 concurrent the runtime queues the excess (a warning, not a refusal), but past the 1000-agent lifetime total the runtime throws, so treat that warning as a real bug.

Counts are REPRESENTATIVE, not exact production — fixtures are minimal by design. A green
dry-run validates the machine, not the meaning: it cannot judge prompt quality, a
schema's `required` set, or the effort tier. For that, do a NARROW real run on one tiny
scope (§16) — `dry-run.mjs --mode real --scope <path>` prints the exact `Workflow(…)`
invocation for you to authorize and spawns nothing.

Do not rely on raw `node --check`: a workflow body's top-level `return` and
`export const meta` parse under no single module mode, so it rejects a valid file either
way. The linter and the dry-run are the dependable checks.

---

## Step 6 — Run, watch, iterate

Run a named workflow with `Workflow({ name: 'review-changes' })`, or a file with
`Workflow({ scriptPath: '…' })`. It runs in the **background** — the call returns
a run ID immediately and a `<task-notification>` arrives on completion. Watch it
live with the `/workflows` command and drill into any agent mid-run; the safe way to stop,
pause, and resume it is the **Stop & resume** section at the top of this skill.

A user reaches a workflow from their side in three ways: a saved or bundled command
(`/deep-research …`, or any workflow saved to `.claude/workflows/`); the `ultracode`
keyword in a prompt (or asking "use a workflow" in plain words), which makes Claude
write a one-off workflow for that task; or `/effort ultracode`, which lets Claude
plan a workflow for every substantive task in the session. Saving a good run is
`s` in `/workflows`, which writes the script to `.claude/workflows/` (project) or
`~/.claude/workflows/` (personal) as a reusable `/<name>` command.

To iterate during authoring, **edit the saved file** and resume it (see **Stop & resume**
above): every `agent()` call before your first edit replays from cache, and only the changed
call onward re-runs. Never re-paste the whole script after the first run — edit the file.

---

## Step 7 — Capture a run ledger for safe resume (required)

The **Stop & resume** section above is the procedure; this step is the one habit that makes it
reliable. The moment `Workflow` returns, record a **run ledger**: a small file (in the session
scratch dir, never the repo) holding the run ID, the launched `scriptPath`, the `args`/scope,
and the exact `Workflow({ scriptPath, resumeFromRunId })` command. Copy
`assets/templates/run-ledger.template.md` and update it on every resume or restart. Without the
captured run ID a later turn cannot resume — it can only start over.

The ledger is **not** the journal. The journal (`journal.jsonl`, written automatically by the
runtime in the run directory) is the cache of agent results that *does* the resuming; the
ledger is your one-line note of the run ID needed to *trigger* a resume. You write the ledger;
the runtime writes the journal. Lose the run ID and the journal is still on disk, but no later
turn knows which run to resume — so it starts over.

The ledger is only useful if a later turn does not silently invalidate the cache, so it
also records the cache-invalidation rules that keep a resume from silently re-running work:

- **`schema`, `model`, `isolation`, and `agentType` are the resume cache key** (full table in
  `references/api-reference.md` §5), and the prompt text is hashed into it too. Change any of
  them — or the `args` that feed a prompt — and that call and everything after it re-runs live.
  `label`, `phase`, `effort`, and `stallMs` are **not** in the key; tune them freely.
- **Do not edit the launched script while the run is resumable** — any cache-key change re-runs
  that call onward. Edit only when you *intend* to re-run from that point (the Step 6 loop).
- **Launch from a stable on-disk `scriptPath`**, so the exact bytes that ran stay on disk to
  replay against; an inline `script` string leaves nothing stable to resume from.

---

## Gotchas — check every one before you hand over the file

These are the mistakes that actually break workflows:

- **Determinism bans.** `Date.now()`, `Math.random()`, and argless `new Date()`
  **throw** inside a workflow — they would break resume. Pass timestamps in via
  `args` and stamp results *after* the workflow returns; vary "randomness" by
  loop index instead. `new Date(specificValue)` is fine.
- **No filesystem, no Node APIs** in the orchestrator. No `require`, `fs`,
  `process`. Any file read/write/Bash work belongs **inside an `agent()`** — the
  subagent has the normal tools; the orchestrator does not.
- **`parallel()` takes thunks, not promises.** It must be
  `[() => agent(...), () => agent(...)]`, never `[agent(...), agent(...)]`. Bare
  calls start immediately and defeat the concurrency limiter.
- **A `pipeline()` stage callback gets `(prevResult, originalItem, index)`.** A
  stage that takes only `prevResult` cannot label or scope by the source item — it
  loses the `originalItem`/`index` it needs to name `verify:${file}` or branch on
  position, and silently mislabels or mis-scopes. Take all three params in any
  stage past the first: ``(review, file, i) => agent(…, { label: `verify:${i}` })``.
- **Always `.filter(Boolean)`.** `parallel()` and `pipeline()` put `null` in the
  slot of any item that threw, was skipped, or was dropped by the budget. The
  result arrays have holes by design.
- **`meta` is a pure literal and the first statement.** No dynamic values, no
  code before it.
- **Open-ended loops need a hard stop** — a counter (`while (found < 10)`) or a
  budget guard (`while (budget.total && budget.remaining() > 50_000)`). With no
  budget set, `budget.remaining()` is `Infinity`; an unguarded loop sprints into
  the 1000-agent lifetime cap and throws.
- **`isolation: 'worktree'` is expensive** (~200–500 ms + disk per agent). Use it
  only when parallel agents mutate files and would otherwise collide.
- **Grant permissions before a long parallel run.** Subagents run in `acceptEdits`
  mode and inherit the session tool allowlist; a non-allowlisted shell, web, or MCP
  call can still surface a mid-run permission prompt and stall the run.
- **Fence untrusted content an agent reads.** When an `agent()` processes
  attacker-influenceable input — a fetched page, a third-party doc, a user-supplied
  string, source of unknown origin — prefix it with a policy that names the content as
  DATA and wrap the text in an explicit fence, so instruction-shaped text inside it is not
  obeyed (`references/patterns.md` §18). A workflow over only trusted in-repo material does
  not need this.
- **The body is JavaScript only.** TypeScript syntax — type annotations,
  interfaces, `as` casts — is a parse error.
- **No backticks anywhere in `meta`.** The linter reads any backtick inside the
  `meta` literal — even one inside a quoted string — as a template literal and
  rejects the file. Write identifiers in `name`/`description`/`phases` as plain text.
- **Call a nested `workflow()` once with the whole work-set, not per item in a
  loop.** Per-item calls don't share the child's cache or closure, so overlapping
  discovery is redone per item and an item primary in one call is mis-classified as
  secondary in another. Pass the full set in one call (patterns reference §15).
- **Key orchestration maps by a compound `owner|id`, not a bare id, when the id is
  not globally unique.** If the same logical id recurs under different owners (a
  mirrored/counterpart record reusing a slug across groups), a bare-id map silently
  merges across owners and corrupts the data; a composed key such as `owner + '|' + id`
  keeps them distinct.
- **Mark derived state on the branch that actually contributes, not before the
  guard.** `set.add(x)` placed *above* an `if (!keep) continue` over-reports `x` as a
  contributor even when it is skipped; move the `add` inside the keeping branch so the
  set mirrors what was really used.

---

## Worked example

For a complete runnable workflow — fan out one reviewer per dimension, then verify
each finding the moment its review lands — read `assets/examples/review-branch.js`.
It is the canonical `pipeline` + nested `parallel` shape, with structured `schema`
on every stage and an independently-tiered `model: 'haiku'` / `effort: 'high'`
verify stage. `references/patterns.md` §3 is the same shape stripped to its core.
