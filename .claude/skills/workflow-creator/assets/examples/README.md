# Example workflows

Complete, runnable workflow scripts, each lint-clean under `scripts/validate-workflow.mjs`. Find the closest match to the job at hand, read it, then adapt it.

| [INDEX] | [FILE]                          | [TOPOLOGY]                | [DEMONSTRATES]                                                                                    |
| :-----: | :------------------------------ | :------------------------ | :-------------------------------------------------------------------------------------------------- |
|  [01]   | `review-branch.js`              | pipeline + nested `parallel` | structured `schema` on every stage, a Sonnet verify stage, `phase` set inside stages            |
|  [02]   | `implement-and-review.js`       | `do/while` loop           | a round cap, a `passed` boolean driving the loop, `args` as a plain task string                  |
|  [03]   | `planning-card-triage.js`       | list → pipeline           | `args` fields read directly, a priority `.filter()` + early `return`, a CLI call inside an agent |
|  [04]   | `dead-code-sweep.js`            | loop-until-dry            | a dry-streak counter, a hard `MAX_ROUNDS` cap, parallel removal under `isolation: 'worktree'`    |
|  [05]   | `api-contract-drift-detector.js` | fan-out with a barrier   | a deliberate `parallel()` barrier, an `args.types` seed that skips discovery, Sonnet fan-out     |
|  [06]   | `geometry-parity-audit.js`      | parallel → barrier        | a barrier because clustering needs the whole set, a Sonnet compare stage, an `args.ops` seed     |
|  [07]   | `route-and-refactor.js`         | routing (dispatch table)  | a classifier discriminant, a `ROUTES` table, unroutable → `null` → `.filter(Boolean)`            |
|  [08]   | `rebuild-and-reconcile.js`      | fan-out → reconcile       | deferrals as DATA with a file LIST, union-find clustering, a separate per-claim verifier         |

What to copy from them:

- Setting a model (rule: api reference). `review-branch.js`, `api-contract-drift-detector.js`, and `geometry-parity-audit.js` push a whole cheap mechanical fan-out to `model: 'sonnet'` and mirror it on the matching `meta.phases[]` entry. `route-and-refactor.js` tiers per ROW instead of per phase: only the mechanical SQL route carries `model: 'sonnet'`, and its phase entry has no model — a phase that mixes models cannot carry one label.
- Tiering reasoning (`effort`), independent of the model. `review-branch.js` drops the verify stage to `model: 'sonnet'` yet keeps `effort: 'high'`, so a cheap model still reasons hard on the adversarial refute; `planning-card-triage.js` runs the mechanical card-pull at `effort: 'low'` and the completeness check at `effort: 'high'`; `dead-code-sweep.js` runs its finder at `effort: 'low'`.
- Structured output. Every example that later reads a field off a result defines a JSON Schema `const` and passes it as `schema`, so the next line is plain JavaScript. Schemas are STRICT at every level: `additionalProperties: false`, `required` listing every property, conditional fields required-but-empty — the codex `--output-schema` endpoint rejects anything looser, and the same shape keeps native agents honest.
- Heavy products. These examples all stay under the ~50-row line and paste inline; past it, a lane writes its product to run scratch and returns the thin receipt — the patterns reference report-file shape is the law.
- Reading `args` (rule: api reference). `planning-card-triage.js` reads object fields with a literal default (`args?.minPriority ?? 'high'`); `api-contract-drift-detector.js` and `geometry-parity-audit.js` take an optional array field that overrides a discovery step; `route-and-refactor.js` takes a top-level array with a default list; `implement-and-review.js` takes a plain task string. None of them parse `args` — there is nothing to parse.
- A hard stop on every loop. `implement-and-review.js` (`MAX_ROUNDS`) and `dead-code-sweep.js` (`DRY_STREAK` plus `MAX_ROUNDS`) — open-ended loops always carry a counter or a budget guard.
- `pipeline` against `parallel`. `review-branch.js` and `planning-card-triage.js` stream with `pipeline`; `api-contract-drift-detector.js` and `geometry-parity-audit.js` use `parallel` as a DELIBERATE barrier, and each says in a comment why the whole result set is genuinely needed at once.
- Routing. `route-and-refactor.js` threads a `ROUTES` table into the thunk: a plain-JS classifier maps each item to a route key, the row supplies the specialist prompt and its model, and an unmatched item falls out at `.filter(Boolean)` — one discriminant and one table, never a family of near-identical entrypoints.

Running one:

```js
Workflow({ scriptPath: '<skill-dir>/assets/examples/review-branch.js' })
```

Or copy the file into `.claude/workflows/` and invoke it by its `meta.name`:

```js
Workflow({ name: 'review-branch' })
```

Examples that take input are invoked with `args` — the header comment in each file gives the exact shape, e.g.:

```js
Workflow({ name: 'planning-card-triage', args: { scope: 'libs/csharp/Rasm.Bim', minPriority: 'high' } })
```
