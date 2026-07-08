# Example workflows

Complete, runnable workflow scripts. Each is a real, lint-clean file that passes
`scripts/validate-workflow.mjs` — find the closest match to what you are building,
read it, then adapt it.

| File | Topology | Demonstrates |
|---|---|---|
| `review-branch.js` | pipeline + nested `parallel` | structured `schema` on every stage, a Sonnet verify stage, `phase` set inside stages |
| `implement-and-review.js` | `do/while` loop | a round cap, a `schema` with a `passed` boolean that drives the loop, `args` used as a plain task string |
| `planning-card-triage.js` | list → pipeline | reading `args` fields directly, a priority-rank `.filter()` + early `return`, an `assay` tool call inside an agent |
| `dead-code-sweep.js` | loop-until-dry | a dry-streak counter, a hard `MAX_ROUNDS` cap, parallel removal under `isolation: 'worktree'` that self-reverts |
| `api-contract-drift-detector.js` | fan-out with a barrier | a deliberate `parallel()` barrier, an optional `args.types` seed that skips discovery, `model: 'sonnet'` on the fan-out |
| `geometry-parity-audit.js` | parallel → barrier | a barrier because clustering divergences needs the whole set, a Sonnet compare stage, an optional `args.ops` seed that skips the discovery agent |
| `route-and-refactor.js` | routing (dispatch table) | a classifier discriminant, a `ROUTES` table, an unroutable file → `null` → `.filter(Boolean)`, `model: 'sonnet'` on the mechanical SQL row, a terminal synthesis stage |
| `rebuild-and-reconcile.js` | fan-out → reconcile (cluster → fix → verify) | deferring cross-file work as DATA (a file LIST), union-find clustering by shared file, a separate per-claim adversarial verifier, a count-barrier early-exit |

## What to copy from them

**Setting a model** (the rule lives in `../../references/api-reference.md` §5).
`review-branch.js`, `api-contract-drift-detector.js`, and `geometry-parity-audit.js`
push a whole cheap, mechanical fan-out to `model: 'sonnet'` and mirror it on the
matching `meta.phases[]` entry. `route-and-refactor.js` tiers per *row* instead of
per phase: only the mechanical SQL `ROUTES` row carries `model: 'sonnet'`, so its one
`agent()` call reads `model: route.model` and its phase entry has no `model` —
a phase that mixes models cannot carry one label.

**Tiering reasoning (`effort`), not the model.** `effort` is the orthogonal axis —
it tiers how hard the agent reasons, independent of which model runs.
`review-branch.js` drops the verify stage to `model: 'sonnet'` yet keeps
`effort: 'high'`, so a cheap model still reasons hard on the adversarial refute;
`planning-card-triage.js` runs the mechanical card-pull at `effort: 'low'` and the
adversarial completeness check at `effort: 'high'`; `dead-code-sweep.js` runs its
finder at `effort: 'low'`. Reach for `effort` to dial reasoning per stage without
moving off the session model, and combine it with `model` when a stage is both
cheap *and* needs to think.

**Structured output (`schema`).** Every example that later reads a field off a
result defines a JSON Schema `const` and passes it as `schema` — so `agent()`
returns a parsed object and the next line is plain JavaScript (`review.passed`,
`issues.filter(...)`). Schemas are STRICT at every level: `additionalProperties:
false` on every object, `required` listing every property, a conditional field
designed required-but-empty (`''`/`[]`) — the codex `--output-schema` endpoint
rejects anything looser, and the same shape keeps native agents honest.

**Scratch artifacts (heavy products).** Run scratch is
`.claude/scratch/<workflow-name>/` — one folder per workflow, gitignored,
ephemeral; file grammar `<scope>-<lane>-<artifact>.<ext>` (lane = short semantic
slug like `s0`/`gov`/`rip-python`; artifact = `task`/`schema`/`report`/`stderr`;
no agent names, timestamps, or run IDs). A lane whose product is heavy (~50+
rows) writes it there as one JSON file and returns only the thin receipt
`{ok, report, entries, headline, failure}`; failure lives in the envelope, never
as sentinel rows in the data. These examples all stay under that line and paste
inline — `.claude/workflows/realize.js` and `cold-verify.js` are the worked
receipt pattern, and SKILL.md "Data flow between stages" is the law.

**Reading `args`** (the rule lives in `../../references/api-reference.md` §4).
`planning-card-triage.js` reads object fields with a literal default
(`args?.minPriority ?? 'high'`); `api-contract-drift-detector.js` and
`geometry-parity-audit.js` take an optional array field that *overrides* a discovery
step (`Array.isArray(args?.types) ? args.types : null`, then enumerate when null);
`route-and-refactor.js` takes a top-level array with a default list
(`Array.isArray(args) && args.length ? args : [...]`); `implement-and-review.js`
takes a plain-text task string. None of them parse `args` — there is nothing to parse.

**A hard stop on every loop.** `implement-and-review.js` (`MAX_ROUNDS`) and
`dead-code-sweep.js` (`DRY_STREAK` + `MAX_ROUNDS`) — open-ended loops always need
a counter or a budget guard.

**`pipeline` vs `parallel`.** `review-branch.js` and `planning-card-triage.js` use
`pipeline` (no barrier — each item advances on its own).
`api-contract-drift-detector.js` and `geometry-parity-audit.js` use `parallel` as a
*deliberate* barrier — and each says in a comment why the whole result set is
genuinely needed at once.

**Routing (a dispatch table).** `route-and-refactor.js` is fan-out with a `ROUTES`
table threaded into the thunk: a plain-JS classifier maps each item to a route key,
the `ROUTES` row supplies the specialist prompt (and its `model`), and an item that
matches no row returns `null` and falls out at `.filter(Boolean)`. Copy it when one
loop must hand different items to different specialists — never grow a `Get`/`GetBy`
family of near-identical entrypoints when one discriminant + one table will do.

## Running one

```js
Workflow({ scriptPath: '<skill-dir>/assets/examples/review-branch.js' })
```

Or copy the file into `.claude/workflows/` and invoke it by its `meta.name`:

```js
Workflow({ name: 'review-branch' })
```

Examples that take input are invoked with `args` — see the header comment in
each file for the exact shape, e.g.:

```js
Workflow({ name: 'planning-card-triage', args: { scope: 'libs/csharp/Rasm.Bim', minPriority: 'high' } })
```
