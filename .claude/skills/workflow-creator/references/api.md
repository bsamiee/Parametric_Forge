# Workflow Runtime Reference

Claude Code's `Workflow` tool runs one author-written JavaScript file that deterministically orchestrates fresh-context subagents in a sandbox. Orchestration shapes live in the patterns reference; concurrency economics in the throughput reference; resume and recovery in the recovery reference.

## [01]-[MODEL]

A workflow is a JavaScript program that orchestrates subagents. Its author writes one file; the `Workflow` tool runs it in a sandbox.

One word matters: deterministic. In a normal session, the model decides the next step — reads a result, thinks, picks a tool — and that control flow varies run to run. A workflow inverts it: the loops, the conditionals, the fan-out, the retries are plain JavaScript. A model does only the leaf work inside each `agent()` call. Orchestration spends zero tokens and behaves identically every run.

One-sentence model: a script runs in a sandbox → every `agent()` call spawns a fresh subagent with its own clean context window → the script collects results with ordinary JavaScript → the return value comes back as the tool result.

Fresh context windows are the point. A single session has one context window; a big multi-step job fills it with every file and every intermediate thought. In a workflow each `agent()` gets a brand-new empty context, does its one job, returns only its result, and its context is discarded. Main conversation barely grows, agents cannot contaminate each other, and the job touches far more material than one window holds.

## [02]-[INVOCATION]

`Workflow` takes at least one of `script`, `name`, or `scriptPath`:

| [INDEX] | [FIELD]           | [TYPE] | [MEANING]                                                                                             |
| :-----: | :---------------- | :----- | :---------------------------------------------------------------------------------------------------- |
|  [01]   | `script`          | string | A self-contained workflow script; must begin with `export const meta = {…}`                           |
|  [02]   | `name`            | string | A predefined workflow — built-in, or a file under a `.claude/workflows/` directory                    |
|  [03]   | `scriptPath`      | string | Path to a workflow file on disk; takes precedence over `script` and `name`                            |
|  [04]   | `args`            | any    | Optional input exposed to the script as the global `args`, as structured data; `undefined` if omitted |
|  [05]   | `resumeFromRunId` | string | A prior run ID (`wf_…`) to resume from; same session only (recovery reference)                        |

Persist-and-edit loop: every invocation writes the script to a file in the session directory and returns that path. Iterate by editing the saved file with Write/Edit and re-invoking with `{ scriptPath }` — never re-send the full script text after the first run.

Placement and precedence:

- Project workflows live in `.claude/workflows/`, personal ones in `~/.claude/workflows/`; a saved workflow runs as `/<name>`. On a name collision the project one wins.
- In a monorepo, project workflows load from every `.claude/workflows/` between the working directory and the repo root; the closest definition of a name wins, and a save lands in the closest existing `.claude/workflows/` directory.
- `name` inside `meta` — not the filename — is the workflow's name.

User-side entry points: a saved or bundled command (`/deep-research …`); the `ultracode` keyword in a prompt (a plain-words "use a workflow" works identically); or `/effort ultracode`, which plans a workflow for every substantive task in the session. Saving a good run is `s` in `/workflows`.

Runtime posture knobs, all advisory or off-switches — none change script semantics:

- Workflow-size setting (`/config` → Dynamic workflow size) sends an agent-count aim per script written: `unrestricted` (default), `small` under 5, `medium` under 15, `large` under 50. Guidance only; the runtime caps still govern.
- A run that schedules more than 25 agents or projects past 1.5 million tokens raises an advisory large-workflow warning in the task panel; a set size guideline replaces the 25-agent threshold, and ultracode sessions suppress the warning.
- Off switches: the `/config` toggle, `"disableWorkflows": true` in settings, or `CLAUDE_CODE_DISABLE_WORKFLOWS=1` at startup. Disabling removes bundled commands, the keyword trigger, and the ultracode effort tier.
- Launch prompt shows the planned phases with run / remember-approval / view-raw-script / cancel; in auto permission mode consent is recorded on first launch. Bypass-permissions and headless runs start without prompting.

## [03]-[ANATOMY]

Two parts, in this order; the parser is strict about both.

### [03.1]-[META_FIRST_LITERAL]

Every workflow's first statement must be `export const meta = {…}`, and the object must be a pure literal: no variables, no function calls, no spreads, no template interpolation. A parser walks the syntax tree and rejects anything else, along with reserved keys (`__proto__`, `constructor`, `prototype`). A backtick anywhere in the literal is rejected — the parser reads any backtick as a template literal, even inside a single-quoted string — so `name`, `description`, and `phases` stay free of code-fenced spans.

```js conceptual
export const meta = {
    name: 'find-flaky-tests', // required — non-empty string
    description: 'Find flaky tests and propose fixes', // required — shown in the permission dialog
    whenToUse: 'CI is intermittently red', // optional — shown in the workflow list
    phases: [
        // optional — one entry per phase() call
        { title: 'Scan', detail: 'grep test logs for retries' },
        { title: 'Fix', detail: 'one agent per flaky test', model: 'sonnet' },
    ],
};
```

`phases[].title` is matched exactly against `phase()` calls. `phases[].model` is a label, not a setting: the binary shows it in the permission dialog, but no code reads it to pick a model. Only the `model` option on each `agent()` call sets the model — a re-tiered phase sets both, or the dialog lies.

### [03.2]-[BODY]

Everything after `meta` is the body. It runs inside an `async` function, so `await` works at the top level. Orchestration globals are injected — nothing is imported. Its `return` value becomes the tool result. Standard JS built-ins (`JSON`, `Math`, `Array`, `Map`, `Set`, …) are available; section [10] lists what is removed. Body source is JavaScript only — TypeScript syntax (type annotations, `interface`, `as` casts) is a parse error.

### [03.3]-[PROMPT_STRINGS]

Prompts are the bulk of a workflow. Keep source lines near 150 columns by splitting one string across lines with adjacent `+` concatenation — JavaScript folds adjacent string operands into one value:

```js conceptual
const PROMPT =
    'TASK: realize the open cards of `' +
    folder +
    '` into design fences ' +
    'at the doctrine bar. Read each card body, the pages it seams to, and ' +
    'verify every novel member before writing.';
```

- Break at a space and keep that space on the left segment; dropping it fuses two words — a silent prompt change.
- Never wrap with a multi-line template literal: real newlines inject `\n` into the value, changing what the agent reads and the resume-cache key. `+` concatenation changes the source only, never the value.
- Receipts and rosters interpolate live at author time — `+ JSON.stringify(x) +` or a single-line `${JSON.stringify(x)}`. A `__TOKEN__` placeholder patched later and a `${'$'}{…}` escape both ship literal text — the script parses, the run launches, and the stage fires with no data — so the linter flags both shapes. When patching a persisted script with `sd`, `$` is a capture reference — patch with `sd -F` or Edit, then re-run the linter before resuming.
- Body prompts only; never wrap inside `meta` — a long `meta.description` stays one line.

### [03.4]-[FILE_ORGANIZATION]

A workflow reads top-to-bottom as the `meta` manifest, then the body in this fixed section order (omit any a file does not need). Mark each with a divider `// --- [LABEL]` and dash-fill:

```js conceptual
// --- [CONSTANTS] ---------------------------------------------------------------------
// dependency-free knobs: CAP, BATCH, static tier/config tables

// --- [INPUTS] ------------------------------------------------------------------------
// args read + derived scope/target/root (depends on the args global)

// --- [MODELS] ------------------------------------------------------------------------
// JSON Schemas for structured agent output

// --- [DOCTRINE] ----------------------------------------------------------------------
// shared prompt-law TEXT consts woven into prompts; a composed DOCTRINE const comes LAST

// --- [OPERATIONS] --------------------------------------------------------------------
// pure helpers: pool, clustering, prompt builders, dispatch tables

// --- [COMPOSITION] -------------------------------------------------------------------
// Run composition: phase()/agent()/pipeline()/parallel()/log() + reshaping + final return

// --- [SUB_SECTION_STYLE]
```

Inside a long `[COMPOSITION]`, mark each phase with a bare subsection divider whose label is the `phase()` title in UPPER_SNAKE (`// --- [RECONCILE]`, no fill). Rules that bite:

- Knobs (`CAP`/`BATCH`) live in `[CONSTANTS]` at the top, never buried in the pool block.
- args-derived values are `[INPUTS]`, never `[CONSTANTS]` — they depend on the runtime `args`. An input derived through a helper co-locates that helper in `[INPUTS]`.
- A const that references a function or a later value is not a `[CONSTANTS]`: a dispatch table over the prompt builders is `[OPERATIONS]` after them; a composed `DOCTRINE` const follows the blocks it joins.
- Banned drift labels: `[HARNESS]` `[SCHEMAS]` `[SCHEMA]` `[LAW]` `[CONFIG]` `[PROMPTS]` `[HELPERS]` `[UTILS]` `[COMMON]` `[MISC]` `[FUNCTIONS]` `[LAYERS]` `[IMPORTS]` `[INTERFACES]` `[ENUMS]` `[DTO]` `[QUERIES]` `[FOLDER]` `[SCOPE]` and singular `[INPUT]`.

## [04]-[GLOBALS]

| [INDEX] | [GLOBAL]                      | [SIGNATURE]                                      | [PURPOSE]                                      |
| :-----: | :---------------------------- | :----------------------------------------------- | :--------------------------------------------- |
|  [01]   | `agent`                       | `agent(prompt, opts?) → Promise<string\|object>` | Spawn one fresh-context subagent               |
|  [02]   | `pipeline`                    | `pipeline(items, ...stages) → Promise<any[]>`    | Stream items through stages, no barrier        |
|  [03]   | `parallel`                    | `parallel(thunks) → Promise<any[]>`              | Run thunks concurrently; a barrier             |
|  [04]   | `phase`                       | `phase(title) → void`                            | Start a progress group; later agents join it   |
|  [05]   | `log`                         | `log(message) → void`                            | Emit a narrator line above the progress tree   |
|  [06]   | `console`                     | `console.log(…)`, `.error(…)`, …                 | Output routed into the workflow log            |
|  [07]   | `budget`                      | `{ total, spent(), remaining() }`                | The turn's token target                        |
|  [08]   | `args`                        | any                                              | `args` as structured data; `undefined` if none |
|  [09]   | `workflow`                    | `workflow(nameOrRef, args?) → Promise<any>`      | Run another workflow inline                    |

### [04.1]-[READING_ARGS]

`args` arrives as structured data, exactly as the caller supplied it — no serialization to undo. `Workflow({ args: { minUsers: 5 } })` yields the object; an array stays an array; a string stays a string; nothing passed yields `undefined`. A script needs only a default for the omitted case and a shape check when one workflow accepts both a config object and a free-text task:

```js conceptual
const threshold = args?.minUsers ?? 20; // object input
const scope = Array.isArray(args) ? args : []; // array input
const task = typeof args === 'string' ? args : 'the change described in TASK.md';
```

Never `JSON.parse(args)` unconditionally: objects arrive live and parsing them throws. Default omitted args to a no-op. Text boundaries can supply JSON strings, so object-reading workflows normalize once at `[INPUTS]`: `(typeof args === 'string' && /^\s*[\[{]/.test(args)) ? JSON.parse(args) : args`.

Saved workflows receive args through `Workflow({ scriptPath, args })`. A launch that drops them relaunches with inline `script` content or encodes scope in the workflow file.

## [05]-[AGENT]

```js conceptual
const text = await agent('Summarize the README.'); // → string
const data = await agent('List the deps.', { schema: DEPS_SCHEMA }); // → validated object
```

Without `schema`, `agent()` returns the subagent's final text verbatim. With `schema`, it returns a validated object. If the user skips the agent from `/workflows`, `agent()` returns `null` — the reason results get `.filter(Boolean)`.

| [INDEX] | [OPTION]    | [TYPE]       | [EFFECT]                                                                                           |
| :-----: | :---------- | :----------- | :------------------------------------------------------------------------------------------------- |
|  [01]   | `label`     | string       | Display name in `/workflows`; defaults to the prompt's first 60 chars; not in the resume cache key |
|  [02]   | `phase`     | string       | Assign to a named progress group; set inside `pipeline`/`parallel`; not in the cache key           |
|  [03]   | `schema`    | object       | JSON Schema forcing structured output; `agent()` returns the validated object                      |
|  [04]   | `model`     | string       | Per-agent model: `'sonnet'`/`'opus'`/`'fable'`/`'inherit'` or a full ID; `'sonnet'` is the floor   |
|  [05]   | `effort`    | string       | Reasoning tier `'low'`…`'max'`, independent of `model`; not in the cache key                       |
|  [06]   | `isolation` | `'worktree'` | Fresh git worktree per agent; its cost and the case that earns it, throughput reference            |
|  [07]   | `agentType` | string       | Run as a registered subagent type; validated against the live registry                             |

`schema`, `model`, `isolation`, and `agentType` enter the resume cache key with the prompt text. `label`, `phase`, and `effort` never invalidate a cached result.

Editing workflow text separates wires from prose. Wires include dispatch options and maps, labels that key reports or journals, register values controlling branches, interpolated role lines, and argument specifications passed to delegates. Prose includes metadata narration, comments, and prompt framing. Classify the sentence by its consumer before editing it.

### [05.1]-[MODEL_SETTING]

| [INDEX] | [PASSED]        | [RESOLVES_TO]                                    |
| :-----: | :-------------- | :----------------------------------------------- |
|  [01]   | `'sonnet'`      | the current default Sonnet                       |
|  [02]   | `'opus'`        | the current default Opus                         |
|  [03]   | `'fable'`       | the current default Fable                        |
|  [04]   | `'inherit'`     | the session's main-loop model (same as omitting) |
|  [05]   | a full model ID | passed through unchanged                         |
|  [06]   | omitted         | the session's main-loop model                    |

There is no validation: a typo like `'sonet'` passes through verbatim and the agent fails later at the API call. Spell the alias exactly. Omit `model` for judgment-heavy work so it inherits the capable session model; drop cheap, high-volume, mechanical leaf work a tier, or route a self-contained lane to codex through the codex-lanes reference. `effort` is the orthogonal axis — a cheap model still reasons hard at `'high'`; match `'max'`/`'xhigh'` to synthesis and adversarial judgment, `'low'` to mechanical leaf work.

Not how the model gets set: `meta.phases[].model` (display-only), and the `CLAUDE_CODE_SUBAGENT_MODEL` env var — when set it silently overrides every per-call `model` for the whole session (a user/CI knob the validation section exploits).

### [05.2]-[SCHEMA_OUTPUT]

Runtime compiles the schema with AJV, synthesizes a hidden `StructuredOutput` tool whose input is that schema, and tells the subagent it must call it exactly once. That call is AJV-validated; on a mismatch the agent is handed the error and retries; a subagent that finishes without calling it is nudged up to twice more before failing. Whatever `agent()` returns is the validated tool input.

`agent(…, { schema })` is the workflow's one validation boundary — a codex lane's product arrives as tool-result text under a prose JSON contract and the WRAPPER's receipt schema validates what crosses the wire (codex-lanes reference). Keep schemas strict by convention: `additionalProperties: false`, every key in `required`, conditional fields required-but-empty — the same shape then serves a rare `codex exec --output-schema` leg (a machine parsing a report blind, OpenAI strict profile enforced) without edits.

Rules for computing data properly: use `schema` for anything a later line reads a field off of — free text only when the result passes whole into another prompt; keep schemas small, strict, and `required`-tight, defined as `const`s in the body (never inside `meta`); hand data between stages by stringifying into the next prompt (the orchestrator shares no memory with the subagent); a skipped or failed agent returns `null` even with a `schema`.

### [05.3]-[CUSTOM_AGENT_TYPES]

`agentType` runs the call as a registered subagent type — the built-ins `'workflow-subagent'` and `'workflow-remote-agent'`, or any registered type from `.claude/agents/` or a plugin (e.g. `'Explore'`). An unknown `agentType` throws with the list of available agents. It composes with `schema`. A workflow subagent is told its final text IS the return value — prompt for the data wanted, not a human-facing message.

## [06]-[FLOW]

`pipeline(items, stage1, stage2, …)` runs each item through all stages independently — no barrier between stages; item A reaches stage 3 while item B is still in stage 1. Every stage callback receives `(prevResult, originalItem, index)` — take all three in any stage past the first, or the stage loses the item it needs to label `verify:${file}` or branch on position. A stage that throws drops that item to `null` and skips its remaining stages.

`parallel(thunks)` runs an array of functions concurrently and waits for all of them — a barrier. Its shape is thunks, `[() => agent(…)]`, never bare promises: bare calls start immediately and defeat the concurrency limiter. A thunk that throws resolves to `null`; the call itself never rejects.

One rule: default to `pipeline()`. Reach for `parallel()` only when a stage genuinely needs the entire previous result set at once — dedup or merge across the full set, an early-exit on a total count, a prompt that compares one item against all others. "Flatten/filter first" happens inside a pipeline stage; "cleaner code" is not a reason. Wall-clock economics live in the throughput reference.

## [07]-[BUDGET]

`budget` reflects a token target the user sets with a `"+500k"`-style directive.

| [INDEX] | [MEMBER]             | [MEANING]                                                                  |
| :-----: | :------------------- | :------------------------------------------------------------------------- |
|  [01]   | `budget.total`       | The target, or `null` if none was set                                      |
|  [02]   | `budget.spent()`     | Output tokens spent this turn — main loop and all workflows share one pool |
|  [03]   | `budget.remaining()` | `max(0, total − spent())`, or `Infinity` with no target                    |

That target is a hard ceiling: once `spent()` reaches `total`, further `agent()` calls throw; in-flight agents finish and their results are kept. Guard budget loops on `budget.total` — with no target, `remaining()` is `Infinity` and the loop runs to the agent cap. Codex tokens never register in `spent()`, so a budget-gated loop meters only its native lanes and a codex-heavy run drains far past what the target reflects.

## [08]-[NESTING]

`workflow(nameOrRef, args?)` runs another workflow inline and returns its result — a name for a saved workflow, or `{ scriptPath }` for a file. That child shares this run's concurrency cap, agent counter, abort signal, and token budget. Nesting is one level only — `workflow()` inside a child throws; it also throws on an unknown name, an unreadable path, or a child syntax error. Call the child once with the whole work-set, never per item in a loop — the composition law is the patterns reference.

## [09]-[LIMITS]

| [INDEX] | [LIMIT]                  | [BEHAVIOR_AT_LIMIT]                                                |
| :-----: | :----------------------- | :----------------------------------------------------------------- |
|  [01]   | Lifetime `agent()` calls | Throws `WorkflowAgentCapError`; runaway-loop backstop              |
|  [02]   | Concurrent agents        | Excess calls queue and run as slots free                           |
|  [03]   | Script size              | Rejected before parsing                                            |
|  [04]   | Token budget             | Throws `WorkflowBudgetExceededError`; in-flight finish, none start |
|  [05]   | VM synchronous timeout   | Bounds sync execution only; catches an infinite sync loop          |

- Lifetime `agent()` calls: every loop carries its own guard.
- VM synchronous timeout: never a wall-clock cap.

## [10]-[SANDBOX]

Non-reproducible calls throw — they break resume:

| [INDEX] | [BANNED]                        | [USE_INSTEAD]                                                      |
| :-----: | :------------------------------ | :----------------------------------------------------------------- |
|  [01]   | `Math.random()`                 | Vary the prompt/label by loop index                                |
|  [02]   | `Date.now()`                    | Pass timestamps in via `args`; stamp results after the run returns |
|  [03]   | argless `new Date()` / `Date()` | `new Date(specificValue)` still works                              |

No host access: the orchestrator has no filesystem and no Node.js APIs — no `require`, `fs`, `process`, network. File and shell work belongs inside an `agent()`; the subagent has the normal tools, the orchestrator does not. This is not a restriction to fight — it is the contract that makes resume work.

Subagents run in `acceptEdits` mode and inherit the session tool allowlist regardless of the session's permission mode. File edits are auto-approved, but an unadmitted tool call raises a mid-run permission prompt. Admit required tools before launch.

## [11]-[VALIDATION]

Bundled checks gate every workflow before it spends a token. Run both; reach for an external parser for neither. Raw `node --check` is a dead end — a body's top-level `return` and `export const meta` parse under no single module mode.

Linter checks enforce the parser's hard rules:

```bash template
node ${CLAUDE_SKILL_DIR}/scripts/validate-workflow.mjs <file.js>
```

A missing or non-first `meta`, a non-literal `meta` (a stray backtick included), a missing `name`/`description`, a banned non-deterministic call, and an oversized script are ERRORS — exit 1, fix every one. An `effort`/`model` value outside the allowed set, a host API, and a bare-promise `parallel([agent(...)])` are WARNINGS — exit 0, but each is a real runtime bug, so clear them too. That linter checks rules, not syntax.

Dry-run is the syntax, control-flow, and determinism check, for zero tokens:

```bash template
node ${CLAUDE_SKILL_DIR}/scripts/dry-run.mjs <file.js> [--args '<json>'] [--fixtures '<json>']
```

It re-hosts the unmodified file inside the same `new Function`-wrapped, injected-globals async sandbox the runtime uses, with `agent()` returning schema-shaped fixtures instead of spawning. It runs the real control flow, recurses into nested `workflow()`, runs twice to prove determinism, and reproduces the determinism bans. Read the report for these signals:

- `parseOk` / `ran` — the body parses and completes without a runtime throw; construction with `new Function` catches the unbalanced paren the rule-scanning linter cannot.
- `deterministic` — both runs produced an identical trace; `false` is a hidden non-deterministic escape, which breaks resume.
- `perPhase` + `totalAgents` — unexpected fan-out or a missing phase exposes routing and truthiness-guard defects; supply real shapes with `--fixtures` keyed by agent label.
- `maxConcurrentObserved` — compare observed concurrency with the workflow's declared cap.
- Trace against the committed baseline — a swallowed stage error can leave `ran=true deterministic=true` while its work disappears; a phase contraction after dispatch-helper edits is a defect.

Fixtures are minimal by design, so traces represent control flow rather than production volume. Exercise loops with converging and permanently stuck inputs so the fixpoint and hard stop both fire.

A green simulation validates the machine, not the meaning — blind to prompt quality, schema `required` fit, and effort-tier fit. Close the gap with a narrow real run on the UNMODIFIED file at one tiny scope, scoped by `args`, never by rewriting calls; `dry-run.mjs --mode real --scope <path>` prints that exact invocation without spawning. Only a narrow real run surfaces structured-output conformance, permission boundaries, and host-singleton serialization, and it seeds the resume cache for the full run.

For a cheaper real run, set `CLAUDE_CODE_SUBAGENT_MODEL` in the environment — it overrides every per-call `model` with no source edit; forcing a cheap model from inside the script is a dead end, because `model` is a cache-key field and a rewritten run seeds nothing.
