# The Workflow Tool — Complete Reference

The complete reference for Claude Code's `Workflow` tool. Read this top to bottom the
first time; after that, jump to the section you need.

## Contents

- [The Workflow Tool — Complete Reference](#the-workflow-tool--complete-reference)
  - [Contents](#contents)
  - [1. What a workflow is](#1-what-a-workflow-is)
  - [2. The Workflow tool's input](#2-the-workflow-tools-input)
  - [3. File anatomy](#3-file-anatomy)
    - [Part 1 — `meta` (mandatory, first statement, pure literal)](#part-1--meta-mandatory-first-statement-pure-literal)
    - [Part 2 — the body](#part-2--the-body)
  - [4. The script API](#4-the-script-api)
    - [`args` — reading input](#args--reading-input)
  - [5. `agent()` in full](#5-agent-in-full)
    - [Setting the model](#setting-the-model)
    - [Structured output with `schema`](#structured-output-with-schema)
    - [Custom agent types](#custom-agent-types)
  - [6. `pipeline()` vs `parallel()`](#6-pipeline-vs-parallel)
    - [`pipeline(items, stage1, stage2, …)`](#pipelineitems-stage1-stage2-)
    - [`parallel(thunks)`](#parallelthunks)
    - [The rule](#the-rule)
  - [7. `budget` and token-aware loops](#7-budget-and-token-aware-loops)
  - [8. `workflow()` — nesting](#8-workflow--nesting)
  - [9. Caps, limits, and what happens at each](#9-caps-limits-and-what-happens-at-each)
  - [10. The determinism sandbox](#10-the-determinism-sandbox)
  - [11. Execution, the journal, and resume](#11-execution-the-journal-and-resume)

---

## 1. What a workflow is

A workflow is a **JavaScript program that orchestrates subagents**. You write one
file; the `Workflow` tool runs it in a sandbox.

The word that matters is **deterministic**. In a normal Claude session, *Claude*
decides the next step — it reads a result, thinks, picks a tool. That control
flow is model-driven and varies run to run. A workflow inverts it: the loops, the
conditionals, the fan-out, the retries are **plain JavaScript**. The model only
does the **leaf work** inside each `agent()` call. The orchestration itself spends
zero tokens and behaves identically every run.

The one-sentence model:

> Claude writes a JS script once → the script runs in a sandbox → every `agent()`
> call spawns a fresh subagent with its own clean context window → the script
> collects the results with ordinary JavaScript → the return value comes back to
> Claude as the tool result.

**Why fresh context windows are the point.** A single Claude session has one
context window. Run a big multi-step job inside it and that window fills with
every file and every intermediate thought until you hit the ceiling. A workflow
makes that fight disappear: each `agent()` call gets a brand-new, empty context,
does its one job, returns only its result, and its context is discarded. The
orchestrator never sees the scratch work. So the main conversation barely grows,
agents cannot contaminate each other, and the job can touch far more material
than any one window could hold.

---

## 2. The Workflow tool's input

When Claude calls `Workflow`, it provides one of these. You must supply at least
one of `script`, `name`, or `scriptPath`.

| Field | Type | Meaning |
|---|---|---|
| `script` | string | A self-contained workflow script. Must begin with `export const meta = {…}`. |
| `name` | string | Name of a predefined workflow — built-in, or a file in `.claude/workflows/`. |
| `scriptPath` | string | Path to a workflow file on disk. **Takes precedence over `script` and `name`.** |
| `args` | any | Optional input exposed to the script as the global `args`, **as structured data** — an object/array/string the script reads directly. `undefined` if omitted. See the `args` global below. |
| `resumeFromRunId` | string | A prior run ID (`wf_…`) to resume from. Same session only. |

**The persist-and-edit loop.** Every invocation writes the script to a file in
the session directory and returns that path. The intended iteration loop is: run
once → edit the saved file with Write/Edit → re-invoke with `{ scriptPath }`. You
never re-send the full script text after the first run.

---

## 3. File anatomy

Two parts, in this order. The parser is strict about both.

### Part 1 — `meta` (mandatory, first statement, pure literal)

The very first statement must be `export const meta = {…}`, and the object must
be a **pure literal**: no variables, no function calls, no spreads, no template
interpolation. The parser walks the syntax tree and rejects anything else.
Reserved keys (`__proto__`, `constructor`, `prototype`) are also rejected. A
**backtick anywhere in the literal is rejected** — the linter reads any backtick as
a template literal, even one inside a single-quoted string — so keep `name`,
`description`, and `phases` free of code-fenced spans and write identifiers as plain
text.

```js
export const meta = {
  name: 'find-flaky-tests',            // required — non-empty string
  description: 'Find flaky tests and propose fixes', // required — shown in the permission dialog
  whenToUse: 'CI is intermittently red',  // optional — shown in the workflow list
  phases: [                            // optional — one entry per phase() call
    { title: 'Scan',  detail: 'grep test logs for retries' },
    { title: 'Fix',   detail: 'one agent per flaky test', model: 'haiku' },
  ],
}
```

| `meta` field | Required | Notes |
|---|---|---|
| `name` | yes | Non-empty string. This — not the filename — is the workflow's name. |
| `description` | yes | One line. The text the user sees in the permission dialog. |
| `whenToUse` | no | String. Shown when the workflow is listed. |
| `phases` | no | Array of `{ title, detail?, model? }`. `title` is matched **exactly** against `phase()` calls. `model` here is **display-only** — see the note below. |

> **`phases[].model` is a label, not a setting.** The binary stores it and shows
> it in the permission dialog, but **no code reads it to choose a model**. The
> model is set *only* by the `model` option on each `agent()` call. If a phase
> runs on Haiku, put `model: 'haiku'` both on the `phases[]` entry (so the dialog
> is honest) **and** on every `agent()` call in that phase (so it actually
> happens). The entry alone does nothing.

### Part 2 — the body

Everything after `meta` is the body. It runs inside an `async` function, so you
can `await` at the top level. The orchestration globals are injected — you import
nothing. The body's `return` value becomes the tool result.

Standard JS built-ins (`JSON`, `Math`, `Array`, `Map`, `Set`, …) are available.
See [section 10](#10-the-determinism-sandbox) for what is removed.

---

## 4. The script API

| Global | Signature | Purpose |
|---|---|---|
| `agent` | `agent(prompt, opts?) → Promise<string\|object>` | Spawn one fresh-context subagent. |
| `pipeline` | `pipeline(items, ...stages) → Promise<any[]>` | Stream items through stages, no barrier. |
| `parallel` | `parallel(thunks) → Promise<any[]>` | Run thunks concurrently. A barrier. |
| `phase` | `phase(title) → void` | Start a progress group; later agents join it. |
| `log` | `log(message) → void` | Emit a narrator line above the progress tree. |
| `console` | `console.log(…)`, `.error(…)`, … | A console whose output is routed straight into the workflow log. |
| `setTimeout` / `clearTimeout` | the standard timer pair | Injected, and abort-aware — pending timers are cleared if the workflow is aborted. There is **no** `sleep`; do not busy-wait. Rarely needed in practice. |
| `budget` | `{ total, spent(), remaining() }` | The turn's token target. |
| `args` | any | Whatever was passed as the tool's `args` input, exposed as **structured data** (`undefined` if none). An object stays an object, an array stays an array, a string stays a string — read it directly. See below. |
| `workflow` | `workflow(nameOrRef, args?) → Promise<any>` | Run another workflow inline. |

> **`console`, `setTimeout`/`clearTimeout`, and the `stallMs` option** (section 5)
> are injected globals/options and work in the runtime.

### `args` — reading input

`args` is exposed to the script as **structured data**, exactly as the caller
supplied it. There is no serialization step to undo:

- `Workflow({ args: { minUsers: 5 } })` → `args` is the object `{ minUsers: 5 }`;
  `args.minUsers` is `5`.
- `Workflow({ args: ['alpha', 'beta'] })` → `args` is the array;
  `Array.isArray(args)` is `true` and `args.map(...)` works.
- `Workflow({ args: 'collapse the duplicate mesh codecs' })` → `args` is that
  string.
- Nothing passed → `args` is `undefined`.

So the only handling a script needs is a default for the omitted case, plus a shape
check when one workflow accepts both a config object and a free-text task:

```js
const threshold = args?.minUsers ?? 20            // object input
const scope = Array.isArray(args) ? args : []     // array input
const task = typeof args === 'string' ? args : 'the change described in TASK.md'
```

Never `JSON.parse(args)` — it is already a live value, not JSON text, and parsing
an object throws. A workflow saved as a `/<name>` command receives input the way
the user phrases the invocation, parsed into structured data before the script
runs; the `?? default` is what keeps the file runnable with no args at all.

---

## 5. `agent()` in full

```js
const text = await agent('Summarize the README.')                 // → string
const data = await agent('List the deps.', { schema: DEPS_SCHEMA }) // → validated object
```

**Return value.** Without `schema`, `agent()` returns the subagent's final text
verbatim, as a string. With `schema` (a JSON Schema object), the subagent is
*forced* to return a validated object matching it — no parsing needed; validation
happens at the tool layer and the model retries on a mismatch. If the user skips
the agent from `/workflows`, `agent()` returns `null` — which is why you
`.filter(Boolean)` results.

**Options:**

| Option | Type | Effect |
|---|---|---|
| `label` | string | Display name for this agent in `/workflows`. Defaults to the first 60 chars of the prompt. Not part of the resume cache key — relabelling never invalidates a cached call. |
| `phase` | string | Assign this agent to a named progress group. Use inside `pipeline`/`parallel` stages so concurrent calls land in the right group instead of racing on the global `phase()`. Not part of the cache key. |
| `schema` | object | A JSON Schema. Forces structured output — `agent()` returns the validated object. See **Structured output** below. |
| `model` | string | Per-agent model. `'haiku'`, `'sonnet'`, `'opus'`, `'fable'`, `'inherit'`, or a full model ID. Omit to inherit the session model. See **Setting the model** below. |
| `effort` | string | Reasoning-effort tier for this call — `'low'`/`'medium'`/`'high'`/`'xhigh'`/`'max'` (mirrors `/effort`). Independent of `model` — it tiers the *reasoning*, not the model. Match it to the stage role: `'max'`/`'xhigh'` for synthesis, authoring, and adversarial judgment; `'low'` for mechanical discovery/classification leaf work; omit it to inherit the session tier. NOT part of the resume cache key. |
| `isolation` | `'worktree'` | Run the agent in a fresh git worktree. Expensive (~200–500 ms + disk each). Use **only** when parallel agents mutate files and would otherwise collide; the worktree is auto-removed if unchanged. `'worktree'` is the only accepted value; any other value is rejected. |
| `agentType` | string | Run as a registered subagent type instead of the default workflow subagent. See **Custom agent types** below. |
| `stallMs` | number | Override this agent's stall timeout (default **180000 ms / 3 min**). Raise it for a legitimately slow agent so it is not aborted as "stalled". |

`schema`, `model`, `isolation`, and `agentType` are the four options baked into
the resume cache key — change any of them and that `agent()` call re-runs.
`label`, `phase`, `effort`, and `stallMs` are not part of the cache key and never invalidate a cached result.

### Setting the model

Each `agent()` call runs on its own model. The `model` string is resolved by
Claude Code's normal alias resolver:

| You pass | Resolves to |
|---|---|
| `'haiku'` | the current default Haiku |
| `'sonnet'` | the current default Sonnet |
| `'opus'` | the current default Opus |
| `'fable'` | the current default Fable |
| `'inherit'` | the session's main-loop model (same as omitting `model`) |
| a full model ID (e.g. `'claude-haiku-4-5'`) | passed through unchanged |
| *omitted* | the session's main-loop model |

**There is no validation.** An unrecognised string (a typo like `'hauku'`) is
**not** rejected at parse time — the resolver passes it through verbatim and the
agent fails later when the API call is made. Spell the alias exactly.

Guidance: omit `model` for judgement-heavy work so it inherits the capable
session model; drop **cheap, high-volume, mechanical** leaf work (one-line
classification, refute-this checks, per-item summaries) to `'haiku'`. A
verification or fan-out stage is the usual `'haiku'` candidate.

Two things that are **not** how you set a model:

- `meta.phases[].model` — display-only (see section 3). It does not set anything.
- The `CLAUDE_CODE_SUBAGENT_MODEL` env var — if set, it overrides *every*
  per-call `model` for the whole session. It is a user/CI knob, not something a
  script controls; just know a workflow's `model` opts are silently ignored when
  it is set.

### Structured output with `schema`

By default `agent()` returns the subagent's final text as a **string**. Pass a
`schema` (a plain JSON Schema object) and you instead get a **validated object**
back — ready for the next line of JavaScript, no `JSON.parse`.

The mechanism: the runtime compiles your schema with **AJV**,
synthesises a hidden `StructuredOutput` tool whose input *is* that schema, and
tells the subagent it must call that tool exactly once. The call is
AJV-validated; on a mismatch the agent is handed the validation error and tries
again. If the subagent finishes without ever calling it, the runtime nudges it
up to twice more before failing. The value `agent()` returns is the validated
tool input.

```js
const DEPS = {
  type: 'object',
  required: ['deps'],
  properties: { deps: { type: 'array', items: { type: 'string' } } },
}
const { deps } = await agent('List the npm dependencies.', { schema: DEPS })
```

Rules of thumb for "computing data properly":

- **Use `schema` for anything a later line reads a field off of.** Free text is
  fine only when the result is just passed whole into another agent's prompt.
- **Keep schemas small and `required`-tight.** The schema is a contract — every
  `required` field is one the subagent is forced to produce. Define schemas as
  `const`s in the body (never inside `meta`).
- **To hand data from one stage to the next**, stringify it into the next
  prompt: `agent('Cluster these:\n' + JSON.stringify(items))`. The orchestrator
  has no shared memory the subagent can see — only the prompt text.
- **A skipped or failed agent returns `null`** even with a `schema`. Always
  `.filter(Boolean)` before reading fields off `parallel()`/`pipeline()` results.

### Custom agent types

`agentType` runs the call as a registered subagent type instead of the default
workflow subagent. Valid values are any agent in the live registry — the
built-ins `'workflow-subagent'` and `'workflow-remote-agent'`, plus anything
from `.claude/agents/` or a plugin (e.g. `'Explore'`). An unknown `agentType`
**throws** with the list of available agents (unlike `model`, it *is*
validated). It composes with `schema` — the `StructuredOutput` tool is added on
top of the custom agent's own tools.

**Subagents return raw data, not chat.** A workflow subagent is told its final
text *is* the return value — so prompt it for the data you want, not for a
human-facing message. For structured results, always prefer `schema` over asking
for JSON in prose.

---

## 6. `pipeline()` vs `parallel()`

### `pipeline(items, stage1, stage2, …)`

Runs each item through **all** stages independently. **There is no barrier
between stages** — item A can be in stage 3 while item B is still in stage 1.
This is the **default** for multi-stage work: wall-clock equals the slowest
single item's whole chain, not the sum of the slowest stage at each step.

Every stage callback receives `(prevResult, originalItem, index)` — use
`originalItem`/`index` in later stages to label work without threading context
through earlier return values. A stage that throws drops that item to `null` and
skips its remaining stages.

```js
const out = await pipeline(
  files,
  (file)            => agent(`Review ${file}`, { schema: REVIEW }),
  (review, file, i) => agent(`Verify review of ${file}`, { label: `verify:${i}` }),
)
```

### `parallel(thunks)`

Runs an array of **functions** concurrently and **waits for all of them** — it is
a barrier. Note the shape: an array of thunks, `[() => agent(…), () => agent(…)]`,
**not** an array of promises. A thunk that throws resolves to `null` in the
result array; the call itself never rejects, so `.filter(Boolean)` before use.

```js
const results = await parallel(
  questions.map(q => () => agent(`Research: ${q}`, { schema: RESEARCH }))
)
```

### The rule

**Default to `pipeline()`.** Reach for `parallel()` as a barrier only when a
stage genuinely needs the *entire* previous result set at once:

- dedup or merge across the full set before expensive downstream work,
- an early-exit on a total count ("0 findings → skip verification"),
- a stage whose prompt compares one item against all the others.

Not justified by "I need to flatten/filter first" (do that inside a pipeline
stage) or "it is cleaner" (a pipeline models separate stages fine). A barrier
wastes the idle time of every fast item while it waits for the slowest.

---

## 7. `budget` and token-aware loops

`budget` reflects a token target the user can set with a `"+500k"`-style
directive in their message.

| Member | Meaning |
|---|---|
| `budget.total` | The target, or `null` if none was set. |
| `budget.spent()` | Output tokens spent this turn — across the main loop **and all workflows**. The pool is shared, not per-workflow. |
| `budget.remaining()` | `max(0, total − spent())`, or `Infinity` if no target. |

The target is a **hard ceiling**. Once `spent()` reaches `total`, further
`agent()` calls throw. Guard budget loops on `budget.total` — with no target,
`remaining()` is `Infinity` and the loop runs to the agent cap:

```js
const found = []
while (budget.total && budget.remaining() > 50_000) {
  const r = await agent('Find one more issue.', { schema: ISSUE })
  found.push(...r.issues)
}
```

---

## 8. `workflow()` — nesting

`workflow(nameOrRef, args?)` runs another workflow inline as a sub-step and
returns whatever it returns. Pass a name for a saved workflow, or
`{ scriptPath }` for a file. The child shares this run's concurrency cap, agent
counter, abort signal, and token budget; its agents appear under a nested group
in `/workflows`.

**Nesting is one level only** — calling `workflow()` inside a child throws.
`workflow()` throws on an unknown name, an unreadable path, or a child syntax
error — catch it if you want to degrade gracefully.

---

## 9. Caps, limits, and what happens at each

| Limit | Value | Behaviour when hit |
|---|---|---|
| Lifetime `agent()` calls per run | **1000** | Throws `WorkflowAgentCapError`. A runaway-loop backstop, set far above any real workflow — add a counter or budget guard to your loops. |
| Concurrent agents | **up to 16** (fewer on machines with few CPU cores) | Not an error — excess `agent()` calls **queue** and run as slots free. You can pass 100 items to `parallel()`; up to 16 run at once, all 100 finish. The cap scales down with core count, so a small machine runs fewer. |
| Script size | **524288 bytes (512 KB)** | The script is rejected before parsing. |
| Token budget | user-set | Throws `WorkflowBudgetExceededError` once `spent()` reaches `total`. In-flight agents finish and their results are kept; no *new* agents start. |
| Per-agent stall | **180000 ms** (3 min); per-agent override via `stallMs` | An agent with no progress for this long is aborted and retried — up to **5×** — then abandoned (its `agent()` call resolves, so the workflow continues). |
| VM synchronous timeout | **30000 ms** | Bounds *synchronous* execution only — it catches an infinite sync loop. The body is `async`, so a real workflow still runs for many minutes; this is not a wall-clock cap. |

You set the script size and the loop caps directly, and the per-agent stall
window via `stallMs`. The rest is automatic — a wedged agent will not hang the
whole workflow forever.

---

## 10. The determinism sandbox

The script runs in a hardened sandbox — not a normal Node process. The
consequences:

**Non-reproducible calls are banned.** These would make a resume produce
different results, so they **throw**:

| Banned | Use instead |
|---|---|
| `Math.random()` | Vary the agent prompt/label by loop index. |
| `Date.now()` | Pass timestamps in via `args`; stamp results after the workflow returns. |
| argless `new Date()` / `Date()` | `new Date(specificValue)` still works — only "what time is it now" is blocked. |

**No host access.** The orchestrator has **no filesystem and no Node.js APIs** —
no `require`, `fs`, `process`, network. Standard JS built-ins are available. Any
file or shell work belongs **inside an `agent()`**: the subagent has the normal
Read/Write/Bash tools; the orchestrator does not.

**The body is JavaScript only.** TypeScript syntax — type annotations,
`interface`, `as` casts — is a parse error. Write plain JS.

**Subagents run in `acceptEdits` mode and inherit the session tool allowlist.**
File edits inside an agent are auto-approved, but a shell, web, or MCP call that
is *not* on the session allowlist can still raise a permission prompt mid-run —
which stalls a long parallel run until it is answered. Grant those permissions
before launching one.

This is not a restriction to fight — it is the contract that makes resume work.
The orchestrator's job is pure control flow over `agent()` calls.

---

## 11. Execution, the journal, and resume

A workflow does **not** block the conversation:

1. Claude calls `Workflow`. The script is parsed, checked, and persisted to a
   file in the session directory.
2. It launches as a background task. The tool returns immediately with a run ID
   (`wf_…`) and the script path.
3. The body runs; progress events stream to `/workflows`.
4. On completion a `<task-notification>` is delivered into the conversation with
   a summary, the agent count, and the run ID.

**The journal is the cache.** Each run owns a directory under
`~/.claude/projects/<project>/<session>/subagents/workflows/wf_<id>/`, and `journal.jsonl`
inside it is the resume cache. Every `agent()` call appends a `{type:"started", key, agentId}`
record when it begins and a `{type:"result", key, agentId, result}` record carrying the
validated result when it finishes. The `key` is `v2:<sha256>` over the call's prompt plus its
`schema`/`model`/`isolation`/`agentType` **only** — not `label`/`phase`/`effort`/`stallMs`.
Each agent's full transcript is a separate `agent-<id>.jsonl`; the journal — not the
transcripts — is what resume reads, and the runtime writes it automatically (you never write
or construct it).

**Resume replays the journal by key.** `Workflow({ scriptPath, resumeFromRunId })`
re-executes the deterministic script and, for each `agent()` call, recomputes its `key`: a
`result` record in that run's journal returns instantly with no model call; a `started`-only
record (the agent was in-flight when the run stopped) or no record runs live. So **same script
+ same args = a 100% cache hit**, and an edited script replays every unchanged call before the
edit. If the prior run is still going, stop it first.

**Three mistakes restart a run from zero instead of resuming it:**

- **No `resumeFromRunId`.** A bare `Workflow({ scriptPath })` or `Workflow({ name })` is a NEW
  run with an empty journal — it never consults a prior run's cache. The most common cause of an
  unexpected restart.
- **A different session.** The journal lives under the launching session's directory, so a run
  started in another session (or after exiting Claude Code) cannot be resumed; it starts fresh.
  This is a hard platform limit — no ledger or saved run ID recovers a cross-session run.
- **A changed cache key from the top.** Editing the script, or changing the `args` that feed the
  first agent's prompt, changes its `key`, misses the cache there, and re-runs from that point.

Resume needs only two things the launch already hands back — the **run ID** and the
**`scriptPath`**; you never build the journal path yourself. Capture both in a run ledger the
instant a run starts, because the run ID lives only in this session. The **ledger is not the
journal**: the journal is the runtime's automatic result cache that *does* the resuming, while
the ledger is your one-line record of the run ID *to pass back* — lose it and a resumable run
can only restart.

**A lost run ID is recoverable in-session — and "ledger" is a convention, not a platform
object.** The runtime exposes the run ID four ways: the launch tool result prints it with the
exact `Workflow({ scriptPath, resumeFromRunId })` command, the completion `<task-notification>`
repeats it, `/workflows` lists every run by ID, and each run directory is literally named
`wf_<id>` under the session's `subagents/workflows/`. So if the ID has scrolled out of context,
list that directory or open `/workflows`, recover it, and resume — a missing ledger is
inconvenient, not fatal, within the session. The ledger only keeps the ID somewhere a later turn
looks first; a run is unrecoverable solely across a session boundary. (For that cross-session
case the only recourse is manual: read the run's `journal.jsonl` / `agent-<id>.jsonl` to see
what completed and hand-author a continuation script that skips it.)
