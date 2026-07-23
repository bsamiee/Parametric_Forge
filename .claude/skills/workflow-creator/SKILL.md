---
name: workflow-creator
description: >-
    Owns Claude Code workflows end to end, the multi-agent orchestrators in `.claude/workflows/`:
    authoring `meta`, `agent()`, `pipeline()`, `parallel()`, and schemas; editing, validating,
    and dry-running an existing script; launching a run, writing its ledger; recovering one
    through run IDs, `resumeFromRunId`, the `journal.jsonl` result cache, cross-session
    transplant, and continuation scripts. Use for "make a workflow", "run the workflow",
    for any edit under `.claude/workflows/`.
---

# [WORKFLOW_CREATOR]

A workflow is a runnable JavaScript orchestrator for Claude Code's `Workflow` tool: the loops, conditionals, and fan-out are plain deterministic code, and only the leaf `agent()` calls spend tokens — each in its own fresh context window. Two deliverables, both owned here: the file, in `.claude/workflows/<name>.js` (project) or `~/.claude/workflows/` (personal), named by its `meta.name` and never its filename; and the run it produces, whose ledger, live progress, resume keys, and recovery route are as much this skill's territory as the script's syntax.

## [01]-[ROUTING]

[REFERENCES]:
- [01]-[API](references/api.md): every global, option, cap, and the validation rail — the runtime manual.
- [02]-[PATTERNS](references/patterns.md): orchestration catalog.
- [03]-[THROUGHPUT](references/throughput.md): concurrency economics and cross-run law.
- [04]-[RECOVERY](references/recovery.md): resume, transplant, and reconstruction.
- [05]-[EXTERNAL_LANES](references/codex-lanes.md): codex work lanes, the agy (Gemini) read-only review lane.
- [06]-[EXECUTION_STANDARD](references/execution-standard.md): stage-prompt demand bar — hostile floor, writer and reviewer law, consumption ladder.

[TEMPLATES]:
- [01]-[FAN_OUT](assets/templates/fan-out.template.js): known-list fan-out with a barrier before synthesis.
- [02]-[LOOP](assets/templates/loop.template.js): unknown-count loop accumulating to a target or budget floor.
- [03]-[PIPELINE](assets/templates/pipeline.template.js): ordered stages with no barrier — the default multi-stage shape.
- [04]-[RUN_LEDGER](assets/templates/run-ledger.template.md): per-run resume record — run ID, scriptPath, args, resume command.

[EXAMPLES]:
- [01]-[API_CONTRACT_DRIFT_DETECTOR](assets/examples/api-contract-drift-detector.js): correct barrier — per-wire-type checkers, one consolidated PR.
- [02]-[CODEX_LANE_BATCH](assets/examples/codex-lane-batch.js): codex lane composition — blocking wrapper lanes, batched probes, full report reads.
- [03]-[DEAD_CODE_SWEEP](assets/examples/dead-code-sweep.js): loop-until-dry with a seen-set, worktree isolation, and a dry-streak stop.
- [04]-[IMPLEMENT_AND_REVIEW](assets/examples/implement-and-review.js): evaluator-optimizer — a fresh-context evaluator, typed issues fed back.
- [05]-[ORCHESTRATE_WORKERS](assets/examples/orchestrate-workers.js): orchestrator-workers with full typed re-plans built from receipts.
- [06]-[PLANNING_CARD_TRIAGE](assets/examples/planning-card-triage.js): plain-JS control between stages — filter, then realize and verify.
- [07]-[REBUILD_AND_RECONCILE](assets/examples/rebuild-and-reconcile.js): reconcile shape — deferrals cluster by shared file, fixed once per cluster.
- [08]-[REVIEW_BRANCH](assets/examples/review-branch.js): no-barrier verification with model and effort as independent axes.
- [09]-[ROUTE_AND_REFACTOR](assets/examples/route-and-refactor.js): dispatch-table fan-out — one route row per class, an unroutable file falls out.

[SCRIPTS]:
- [01]-[VALIDATE](scripts/validate-workflow.mjs): parser-rule linter — errors exit 1, warnings are real defects.
- [02]-[DRY_RUN](scripts/dry-run.mjs): zero-token simulation under mocked globals with per-phase agent counts.

## [02]-[FIT]

A workflow earns its cost when the work is parallel or multi-stage, orchestration must be deterministic and resumable, and per-step fresh context pays. One subagent, one task: the plain `Agent` tool; a procedure where the model picks the steps each run is a skill; a fixed shape worth rerunning and resuming is a workflow. A single-agent run is the baseline to beat: decomposition pays only for genuinely separable units; a camouflaged dependency chain buys overhead and serial wall-clock. Doubtful fit is stated, the lighter option offered.

## [03]-[SHAPE]

Answer these before writing a line; the answers pick the topology. Write them down for the user — they are the design.

1. Unit of work — the thing one subagent does once. Name it concretely.
2. Count — a known list maps, an unknown count loops, evidence-only worklists take an orchestrator-workers planner re-planned per round on feedback.
3. Topology — the patterns map dispatches by deliverable kind: transformed items, unknown counts, class-shaped routing, emergent worklists, iterate-to-a-bar, contested judgment, deferred cross-item work, dataflow contracts riding any shape. Name the shape from that catalog; never invent an ad-hoc one.
4. Barrier question — a later step needing ALL earlier results at once (dedup, merge, count, early-exit) takes `parallel`; everything else takes `pipeline`, which streams items through stages with no barrier, so wall-clock is the slowest single chain, never the sum of stage maxima.
5. Data question — any result a later line reads a field off of takes a `schema`.

Terminal stages are opt-in, never a default. A reconcile or align stage exists only when workers DEFER cross-item work they cannot do alone — then the deferral travels as data whose resource slot is a LIST (`{files: string[], claim}`), so clustering by shared resource works (patterns reference, the reconcile shape). A pure fan-out legitimately ends at its last per-item stage. A workflow parameterized by a target (file, sub-folder, unit root, several at once) resolves scope with a discovery agent — the orchestrator has no filesystem (patterns reference, the scope shape).

PLAN-PHASE LAW: a phase whose single agent merely lists files or enumerates scope is a defect unless the scoping genuinely requires judgment — decomposition, dependency ruling, risk triage. Deterministic enumeration folds into a discovery stage that also produces real analysis (a map with capability analysis, never a bare roster) or collapses to one cheap low-effort call inside an existing stage; a ceremonial Plan phase that returns a roster the next stage re-derives anyway spends an agent to produce nothing.

## [04]-[LAWS]

Rules that break runs, each carried in depth by its owning reference:

- [01]-[META_LITERAL]: `meta` is a pure literal, the first statement, no backticks anywhere inside it.
- [02]-[NO_WALLCLOCK]: `Date.now()`, `Math.random()`, and argless `new Date()` throw — pass timestamps via `args`; vary randomness by loop index.
- [03]-[NO_NODE_APIS]: Orchestrators hold no filesystem or Node APIs — file and shell work rides `agent()`.
- [04]-[PLAIN_JS]: Every workflow body is plain JavaScript, never TypeScript.
- [05]-[THUNKS_NOT_PROMISES]: `parallel()` takes thunks (`[() => agent(…)]`), never bare promises, which start immediately and defeat the limiter.
- [06]-[FILTER_HOLES]: Always `.filter(Boolean)` on `parallel()`/`pipeline()` results — skipped, failed, and budget-dropped items are `null` holes.
- [07]-[DISK_RECEIPTS]: A lane product past ~50 rows goes to disk; only its thin receipt `{ok, report, entries, headline, failure}` crosses the wire.
- [08]-[FULL_READ]: Terminal readers read every ok report IN FULL — relaying through an intermediate agent truncates silently (patterns reference).
- [09]-[NO_IDLE_WAIT]: No agent idles — a live blocking call is the only legal wait.
- [11]-[HARD_STOP]: Every open-ended loop carries a hard stop — a counter, a budget guard (`budget.total && budget.remaining() > N`), a progress gate.
- [12]-[PROGRESS_GATE]: A fix-verify loop gates on file-changing progress, never the round cap alone.
- [13]-[ARGS_STRUCTURED]: `args` is structured data — read it directly; the tool boundary can hand a JSON-encoded string, so `[INPUTS]` normalizes once with the guarded parse-if-string shim (api reference) and the body never parses again.
- [14]-[SAFE_DEFAULT]: A no-args run defaults to a safe no-op, never a full-corpus sweep.
- [15]-[PROMPT_CONCAT]: Wrap long prompt strings with adjacent `+`, the space kept on the left segment.
- [16]-[NO_TEMPLATE_LITERAL]: Never a multi-line template literal in a prompt — it injects `\n` and changes both the value and the resume key.
- [17]-[LIVE_INTERPOLATION]: Prompts embedding receipts interpolate live: `+ JSON.stringify(receipts) +` or single-line `${JSON.stringify(receipts)}`.
- [18]-[NO_PATCH_TOKENS]: Never a `__TOKEN__` placeholder patched later or a `${'$'}{…}` escape — both ship literal text the agent reads as data.
- [19]-[LINTER_RERUN]: Both patch shapes fail the linter; a patched persisted script re-runs it before the launch is trusted.
- [20]-[INSTANCE_SCRATCH]: Run scratch is minted per INSTANCE: `.claude/scratch/<name>-<slug>-<hash>`, derived deterministically from normalized args.
- [21]-[SCRATCH_KEY]: A per-workflow constant dir mixes concurrent and successive runs' products; a clock- or random-based path breaks resume.
- [22]-[FRAGILE_PROSE]: No prose mirrors what the code owns: a constant's value lives ONLY on its declaration, naming the concept, never the number.
- [23]-[CLAIM_VERIFIED]: A roster, model, or path claim is verified against the code or deleted.
- [24]-[LIVE_CONSTANT]: A prompt needing a tunable interpolates its constant live (`' + CAP + '`).
- [25]-[EXACTNESS_KEPT]: Exactness that governs the actor stays exact — schema bounds, protocol facts, thresholds, notes and counts at their owner.
- [26]-[PRECISION_KEPT]: Hardening removes fragility, never precision.

## [05]-[FILE]

Two parts, strict order. First the `meta` literal:

```js conceptual
export const meta = {
    name: 'review-changes', // required — the workflow's name
    description: 'Review changed files, verify each finding', // required — shown in the permission dialog
    whenToUse: 'Before shipping a branch', // optional — shown in the workflow list
    phases: [{ title: 'Review' }, { title: 'Verify', model: 'sonnet' }],
};
```

`meta.phases[].model` is a dialog label only — the model is set per `agent()` call; a re-tiered phase sets both or the dialog lies. Meta is a selection surface, never a second copy of the prompts: `description` states what the run produces, the args shape, and the phase spine; `whenToUse` is one selection clause; `phases[].detail` names each phase's concept. Law text, consumption protocols, and derived agent tallies live in the prompts and the code — a meta that re-serializes them drifts on every stage edit and buries the contract the dialog exists to show ([22]-[FRAGILE_PROSE]).

Size is never the metric, in meta or in prompts: prose optimizes by density — wording refined per the docgen register until fewer words carry the same guidance — never by dropping guidance the acting agent needs; no gate or script imposes a length cap. Lean-prompt shaping that trims intensifiers and hostile register is codex-lane law (external-lanes reference), never a general bar.

Then the body: async JavaScript with injected globals — `agent(prompt, opts?)`, `pipeline(items, …stages)`, `parallel(thunks)`, `phase(title)`, `log(msg)`, `console`, `budget`, `args`, `workflow(name, args?)` — and the body's `return` becomes the tool result. Full signatures and the `args` shape map live in the api reference.

Three `agent()` options tuned most, independent axes:

- `model` — `'sonnet'`/`'opus'`/`'fable'`/`'inherit'` or a full ID: mechanical leaf work drops a tier, a self-contained lane routes to an external wrapper lane, judgment-heavy work inherits the session model.
- `effort` — `'low'`…`'max'`, independent of `model`. Synthesis and adversarial judgment run high; mechanical leaf work runs `'low'`.
- `schema` — a strict JSON Schema (`additionalProperties: false`, everything required, conditional fields required-but-empty) returning a validated object; one shape serves native lanes and codex `--output-schema` alike.

Body files follow the canonical section order `[CONSTANTS]` `[INPUTS]` `[MODELS]` `[DOCTRINE]` `[OPERATIONS]` `[COMPOSITION]` with `// --- [LABEL]` dividers — placement rules are the api reference's file-organization section.

## [06]-[GATE]

Both bundled checks gate every workflow before it spends a token:

```bash template
node ${CLAUDE_SKILL_DIR}/scripts/validate-workflow.mjs <file.js>
node ${CLAUDE_SKILL_DIR}/scripts/dry-run.mjs <file.js> [--args '<json>'] [--fixtures '<json>']
```

Linter checks enforce the parser's hard rules — errors exit 1 and every one gets fixed; warnings are real defects (runtime bugs, unformatted source), cleared too. Dry-run re-hosts the unmodified file under mocked globals for zero tokens: `parseOk=true ran=true deterministic=true` is the bar, and per-phase agent counts expose fan-out bugs and guard-dropped phases. A green simulation validates the machine, never the meaning — close that gap with a narrow real run on one tiny scope before the full spend. Signals, fixtures, and narrow-run mechanics: api reference, validation section.

A narrow run judges the reasoning path, not only the products: after it lands, read the lane transcripts (`/workflows` raw view), because a schema-valid receipt hides premature exits, wrong-tool selection, and over-verbose queries. Durable workflows keep a fixed rubric-scoped eval corpus and rerun it after prompt or schema changes; dry-run cannot expose a meaning regression.

## [07]-[RUN]

Launch with `Workflow({ name })` or `Workflow({ scriptPath })`; the run goes to the background, returns a run ID immediately, and notifies on completion; `/workflows` watches it live. Once the call returns, write the run ledger (run ID, scriptPath, args, exact resume command) from `assets/templates/run-ledger.template.md` into the session scratchpad — without the captured run ID a later turn only starts over. Pause, stop, resume, cross-session transplant, and continuation-script reconstruction: recovery reference.

Iterate by editing the saved file and resuming — every `agent()` call before the first edit replays from cache, only the changed call onward re-runs. Never re-paste a script after the first run, and never edit a launched script while its run is meant to stay resumable. Saving a good run is `s` in `/workflows`, which makes it a `/<name>` command.

A weak lane repairs itself faster than hand-tuning: dispatch one agent holding the lane's PROMPT and its FAILURE TRANSCRIPT to diagnose why the lane failed and rewrite the prompt or schema, then resume — a model reading its own failure mode finds the fix a cold author misses.
