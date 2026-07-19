---
name: workflow-creator
allowed-tools: Bash(node ${CLAUDE_PROJECT_DIR}/.claude/skills/workflow-creator/scripts/*)
description: >-
    Author runnable workflow scripts for Claude Code's Workflow tool — deterministic
    multi-agent orchestration files under `.claude/workflows/` that fan out fresh-context
    subagents through plain JavaScript control flow: the `meta` block, `agent()`,
    `pipeline()`, `parallel()`, schemas, budgets, resume. Use whenever the user wants to
    create, write, scaffold, design, fix, or debug a workflow — "make a workflow", "turn
    this into a workflow", "orchestrate this with subagents deterministically" — when the
    script format or an erroring run needs explaining, and when a described repeatable
    multi-step or parallel job wants packaging as a workflow even though the word never
    appears. Not for merely running an existing workflow or a one-off single-subagent
    task; whether a workflow is the right execution surface belongs to agent-dispatch.
---

# [WORKFLOW_CREATOR]

A workflow is a runnable JavaScript orchestrator for Claude Code's `Workflow` tool: the loops, conditionals, and fan-out are plain deterministic code, and only the leaf `agent()` calls spend tokens — each in its own fresh context window. Its deliverable is the file, in `.claude/workflows/<name>.js` (project) or `~/.claude/workflows/` (personal), named by its `meta.name`, never its filename.

## [01]-[ROUTING]

[REFERENCES]:
- [01]-[API](references/api.md): every global, option, cap, and the validation rail — the runtime manual.
- [02]-[PATTERNS](references/patterns.md): orchestration catalog.
- [03]-[THROUGHPUT](references/throughput.md): concurrency economics and cross-run law.
- [04]-[RECOVERY](references/recovery.md): resume, transplant, and reconstruction.
- [05]-[EXTERNAL_LANES](references/codex-lanes.md): codex (gpt-5.6) work lanes, the agy (Gemini) read-only review lane.
- [06]-[EXECUTION_STANDARD](references/execution-standard.md): stage-prompt demand bar — hostile stance with the floor and exemplar-seed laws, the writer's ground-up/absorption law, reviewers as rebuilders, the mapping-lane burden-reduction contract with unit-granularity mapping, the two-lane ideation split, the own-pass-first consumption ladder.

[TEMPLATES]:
- [01]-[SKELETONS](assets/templates/): starter skeletons — fan-out, loop, pipeline, and `run-ledger.template.md`.

[EXAMPLES]:
- [01]-[RUNNABLE](assets/examples/): complete runnable examples, each self-described by its header comment.

[SCRIPTS]:
- [01]-[GATES](scripts/): deterministic validate and dry-run gates.

## [02]-[FIT]

Placement across execution surfaces — main turn, fork, subagent, team, workflow — is the agent-dispatch skill's law. One line matters here: a workflow earns its cost when the work is parallel or multi-stage, the orchestration must be deterministic and resumable, and fresh-context isolation per step is an advantage. One subagent doing one task is the plain `Agent` tool; a procedure where Claude picks the steps each run is a skill; a fixed shape worth rerunning and resuming is a workflow. A single-agent run is the baseline every workflow must beat: multi-agent decomposition pays only where the units are genuinely separable — dependency-chained work camouflaged as a fan-out costs the orchestration overhead and returns serial wall-clock anyway. When the fit is doubtful, say so and offer the lighter option.

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
- [10]-[WAIT_ROUNDS]: A wait past one call is orchestration — the agent returns a receipt, `setTimeout` holds time, a fresh agent runs the next round.
- [11]-[HARD_STOP]: Every open-ended loop carries a hard stop — a counter, a budget guard (`budget.total && budget.remaining() > N`), a progress gate.
- [12]-[PROGRESS_GATE]: A fix-verify loop gates on file-changing progress, never the round cap alone.
- [13]-[ARGS_STRUCTURED]: `args` is structured data — read it directly, never `JSON.parse` it.
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
- [25]-[EXACTNESS_KEPT]: Exactness that GOVERNS the acting agent stays exact — schema bounds, protocol facts, thresholds, derivation notes beside their own constant, counts bound to an adjacent named enumeration.
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

`meta.phases[].model` is a dialog label only — the model is set per `agent()` call; a re-tiered phase sets both or the dialog lies. META DISCIPLINE: meta is a selection and dialog surface, not a second copy of the prompts — `description` states what the run produces, the args shape, and the phase spine; `whenToUse` is one selection clause; `phases[].detail` names each phase's concept. Law text, consumption protocols, and derived agent tallies live in the prompts and the code — a meta that re-serializes them drifts on every stage edit and buries the contract the dialog exists to show ([22]-[FRAGILE_PROSE]). Size is never the metric, in meta or in prompts: prose optimizes by DENSITY — wording refined per the docgen register and the `docs/standards/` prose owners until fewer words carry the same guidance — and never by dropping guidance the acting agent needs; no gate or script imposes a length cap. Lean-prompt shaping that trims intensifiers and hostile register is codex-lane law (external-lanes reference), never a general bar. Then the body: async JavaScript with injected globals — `agent(prompt, opts?)`, `pipeline(items, …stages)`, `parallel(thunks)`, `phase(title)`, `log(msg)`, `console`, `setTimeout`, `budget`, `args`, `workflow(name, args?)` — and the body's `return` becomes the tool result. Full signatures, the `args` shape map, and every cap: api reference.

Three `agent()` options tuned most, independent axes:

- `model` — `'sonnet'`/`'opus'`/`'fable'`/`'inherit'` or a full ID, `'sonnet'` the floor: mechanical leaf work drops to `'sonnet'`, a self-contained lane routes to codex (terra default, sol for the hardest legs), judgment-heavy work inherits the session model.
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

A narrow run judges the reasoning path, not only the products: after it lands, read the lane transcripts themselves (`/workflows` raw view), because a schema-valid receipt hides premature exits, wrong-tool selection, and over-verbose queries that only the transcript shows. A DURABLE workflow — one rerun across sessions — additionally earns a small fixed eval set (~15-20 representative `args` inputs with a rubric-scoped judge pass over the products); rerun it after any prompt or schema edit, because the dry-run cannot see a meaning regression.

## [07]-[RUN]

Launch with `Workflow({ name })` or `Workflow({ scriptPath })`; the run goes to the background, returns a run ID immediately, and notifies on completion; `/workflows` watches it live. Once the call returns, write the run ledger (run ID, scriptPath, args, exact resume command) from `assets/templates/run-ledger.template.md` into the session scratchpad — without the captured run ID a later turn only starts over. Pause, stop, resume, cross-session transplant, and continuation-script reconstruction: recovery reference.

Iterate by editing the saved file and resuming — every `agent()` call before the first edit replays from cache, only the changed call onward re-runs. Never re-paste a script after the first run, and never edit a launched script while its run is meant to stay resumable. Saving a good run is `s` in `/workflows`, which makes it a `/<name>` command.

A weak lane repairs itself faster than hand-tuning: dispatch one agent holding the lane's PROMPT plus its FAILURE TRANSCRIPT to diagnose why the lane failed and rewrite the prompt or schema, then resume — a model reading its own failure mode finds the fix a cold author misses.
