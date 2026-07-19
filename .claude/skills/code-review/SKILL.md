---
name: code-review
description: >-
    Local code review through three engines — CodeRabbit (working tree), Greptile (committed
    commits vs base), Macroscope (in-place AST correctness) — driven by one verb rail
    (`launch`, `status --follow`, `kill`, `findings --normalize`, `slice`, `reconcile`,
    `harvest`, `gather`, `round`, `verify`) through the COLLECT -> FIX -> DISPOSITION ->
    DISTILL cycle, with per-reviewer concurrent rounds, cross-engine `gather` union, per-round
    `--focus` aiming, fixer-lane dispatch under the shipped lane-law template, and distillation
    through the reviewer-harvest agent into the `.coderabbit.yaml`, `.greptile/`, and
    `.macroscope/` reviewer-config surfaces. Trigger on any explicit review request,
    autonomously when a review is warranted (code, quality, security), on "run coderabbit",
    "run greptile", or "run macroscope", and when tuning any reviewer config. Hosted PR
    reviewer round-trips belong to pr-loop.
---

# [CODE_REVIEW]

One rail folds CodeRabbit, Greptile, and Macroscope into a single improvement machine: it launches, watches, and harvests each into one normalized finding schema, fixer lanes drain the findings under the shipped lane-law template, and each round distills refuted classes and lessons into the reviewer configs so the next round runs harder.

## [01]-[ROUTING]

[REFERENCES]:
- [01]-[CODERABBIT](references/coderabbit.md): `.coderabbit.yaml` config, the `--agent` stream, and the rich finding store
- [02]-[GREPTILE](references/greptile.md): `.greptile/` cascade, the `--json` envelope and status oracle, and the MCP bridge
- [03]-[MACROSCOPE](references/macroscope.md): `.macroscope/` concern files, the stream grammar, and worktree custody

[TEMPLATES]: the four prompt templates are disjoint — lane-law owns fixer conduct, codex-lane owns dispatch mechanics, harvest-dispatch owns round-instance data, closer-dispatch owns routed-row closure; a fact appearing in two of them is a defect.
- [01]-[LANE_LAW](templates/lane-law.md): fixer conduct law riding the dispatch's developer channel
- [02]-[CODEX_LANE](templates/codex-lane.md): channel-split dispatch form — launch, task message, spawn health and audit
- [03]-[HARVEST_DISPATCH](templates/harvest-dispatch.md): per-round reviewer-harvest prompt — round-instance slots alone
- [04]-[CLOSER_DISPATCH](templates/closer-dispatch.md): routed-row closer prompt — sizing, arming, land-or-refute stance
- [05]-[REFUTED_CLASSES](templates/refuted-classes.yaml): refuted-class registry driving the classifier, recurrence detector, and roster

[SCRIPTS]:
- [01]-[REVIEW_RAIL](scripts/review_rail.py): verb rail printing one JSON receipt per verb

[AGENT]:
- `reviewer-harvest`: owns the DISTILL leg, dispatched via the Agent tool from `[05]`; its standing law lives in its own system prompt

## [02]-[CYCLE]

Every round runs COLLECT -> FIX -> DISPOSITION -> DISTILL on two custody lanes that never mix: work under review stays uncommitted or on its slice commits, while distillation — reviewer configs, `docs/`, `tools/` — commits and pushes to origin's default branch the moment it lands, because hosted engines read the indexed default branch and an unpushed guard protects nothing. Steps run in order; each carries what to watch and the knob that tunes it.

1. [CUSTODY]: commit non-review surfaces first — reviewer configs, `docs/`, `tools/`, `.claude/` infra — so the review scope holds exactly the work under review. WATCH: a reviewed-work file in the custody commit shrinks the next round's scope silently. KNOB: the commit-scope roster.
2. [LAUNCH]: `launch` per engine at its canonical scope ([03]), then run the receipt's `watch_cmd` through Bash `run_in_background`. WATCH: the liveness line — `alive=yes` with a counting-down budget is healthy on blind engines. KNOB: engine choice and `--focus`.
3. [NORMALIZE]: `findings --normalize` per completed round; `gather` unions concurrent engines. WATCH: the provenance histogram before any count judgment — a flat total decomposes into `relitigation|refuted_remint|new_work|late_discovery` before any config takes blame, and rising new-work beside falling relitigation is convergence. KNOB: `--dedup-against`.
4. [SLICE]: `slice --lanes N` into balanced per-lane manifests. WATCH: severity and folder balance across lanes. KNOB: lane count — small slices direct freed capacity into capability depth, never early finish.
5. [FIX]: one keeper per lane under the dispatch form (`templates/codex-lane.md`) — lane law on the developer channel, task instance plus imperative miner-spawn step on the user prompt; each lane returns only its report path, so report bodies never enter the orchestrator's context. WATCH: stderr banners within a minute, spawns audited as `function_call` name `spawn_agent` in the parent rollout. KNOB: model tier and lane-law wording — sharpen by replacement, never accumulate.
6. [RECONCILE]: `reconcile` proves per-lane id bijection and emits the verdict histogram. WATCH: verdict-mix honesty — fixed-versus-upgraded inflation, citation-backed push-back share. KNOB: a dropped finding closes through one focused opus closer armed with the slice's stack doctrine, never a session resume.
7. [CLOSERS]: routing rows drain concurrently over disjoint territories under `templates/closer-dispatch.md` — opus for small single-file work, one fable with stacks arming for family or design work. WATCH: honest land-versus-refute — a mined candidate that cannot ground is refuted with its citation, never forced. KNOB: closer sizing.
8. [DISTILL]: `harvest` assembles the feed and memory proposals; dispatch the reviewer-harvest agent under `templates/harvest-dispatch.md`. WATCH: diff-sample the touched blocks — density rose (fewer words, same law), integrations weave rather than append, additions passed the earn test; the ledger's `trimmed` self-report verifies against the actual diff, never trusted alone. KNOB: the agent file — the single versioned tuning surface.
9. [VERIFY]: project the agent's ledger into `<round-dir>/surface-ledger.json` ([05]), then `verify --round N` proves each guard in its surface's own oracle. WATCH: an ineffective row marks failed wording — harden the owner, never re-skip. KNOB: `templates/refuted-classes.yaml` rows.
10. [CLOSE]: commit and push the distillation lane, then `round` appends the `rounds.jsonl` row and prints the round-over-round delta; a zero-findings round arrives here straight from normalize and closes clean. WATCH: findings trending down while capability rows rise is the goal line. KNOB: none — the ledger is the sole progress instrument.
11. [NEXT]: grade the round on the [GRADING] axes, then pick the next engine — recurrence judges per engine, counts flattening under one engine rotate the next round to another, and `--focus` aims a round within one. Greptile rides the early rounds of a campaign while the accumulated diff still fits its size caps; CodeRabbit carries breadth at any diff size; Macroscope joins whenever its lane is open. WATCH: plateau under a hardened config. KNOB: rotation and focus.

- [FRAMING]: both framings ride every surface — negative framing kills false-positive classes through do-not-flag guards citing the refuting ruling, positive framing steers toward house demands through hunt axes and hit-shape rosters. Hit-shape rosters land on every surface regardless of what an engine emits, because fixer miners execute them — the flywheel: fixer discoveries become next-round hit-shapes.
- [GRADING]: REVIEW-THE-REVIEWER grades every round on FP share, relitigation share, novel-quality share, and hunt-axis fire, ledger-recorded so config changes read before-and-after mechanically. Standing verdict: CodeRabbit emits no missing-capability findings under any `path_instructions` wording — capability-direction rides Macroscope check-run agents and Greptile structured rules.

## [03]-[USAGE]

```bash template
RAIL="uv run ${CLAUDE_SKILL_DIR}/scripts/review_rail.py"
$RAIL launch --reviewer <engine> --scope <scope> [--focus <text-or-file>]   # receipt: round N, pgid, watch_cmd
# run the receipt's watch_cmd through Bash run_in_background; its exit re-invokes the agent
$RAIL status --follow --round <N>
$RAIL findings --normalize --round <N> [--dedup-against <M>]
$RAIL slice --lanes 3 --round <N>
# fixer lanes run here (orchestrator dispatch); each writes <round-dir>/lane-<letter>-report.json
$RAIL reconcile --round <N>
$RAIL harvest --round <N>
# dispatch the reviewer-harvest agent on the feed; persist its ledger as <round-dir>/surface-ledger.json
$RAIL verify --round <N>
$RAIL round --round <N>
```

```bash template
$RAIL launch --reviewer coderabbit --scope uncommitted
$RAIL launch --reviewer greptile --scope base:<prior-boundary>
$RAIL launch --reviewer macroscope --scope base:<default-branch>
$RAIL status --follow --all-live            # run_in_background; exits when every live round is terminal
$RAIL findings --normalize --round <N>      # once per engine round
$RAIL gather --all-live                     # union round: fingerprint collapse, corroborators, max severity
# slice / reconcile / harvest / verify / round then target the gather round
```

Every verb accepts `--round N` and `--dir` and prints one JSON receipt; a refusal exits nonzero carrying `{code, detail}`. `launch` refuses an unsupported engine-scope pair and a live same-engine round loudly; the scope family is `all|committed|uncommitted|base:<ref>|base-commit:<sha>`, and the `--reviewer` selectors on `status`/`kill`/`gather` also take `cr|gt|ms`. `--focus` takes inline text or a file path — greptile rides `--instructions`, coderabbit a round-scoped `-c` instruction file, and macroscope refuses focus loudly because config files are its only steering.

Engine scope selection; each reference owns its engine's mechanics — base resolution, size gating, language routing, and config surface.

- [CODERABBIT]: sweeps working-tree quality and style at full breadth every run — a retry re-spends quota; canonical round `--scope uncommitted`, full scope family accepted. `launch` resolves and injects a base for every working-tree scope, refusing with the persist remedy when none resolves, since the engine otherwise fails within a second while exiting 0. `--light` is the cheap post-fix re-review lever, coderabbit-only.
- [GREPTILE]: hunts cross-file logic over committed commits against a base — uncommitted edits never enter; canonical round `--scope base:<prior-boundary>` after committing the slice, `committed` reviews against the repo default, and `base:`/`base-commit:` refs take any committish. A quota-free client-side preflight refuses an oversized range instantly, so a large campaign lands as slice commits each reviewed at the prior boundary. `--resume` (free continuation of an unfinished review — the stall and kill recovery, never a re-spending relaunch) and `--include` (admit sensitivity-held files) are greptile-only passthroughs.
- [MACROSCOPE]: streams AST-level correctness in place; canonical round `--scope base:<default-branch>` spanning committed branch work plus uncommitted edits, `uncommitted` for tree-only — an in-place run without a base on a branch reviews almost nothing. Always in place — fixes land in the files the review read — and `launch` preflight-sweeps stray review worktrees. Config files are its only steering channel.

Waiting is one mechanic: run the launch receipt's `watch_cmd` through Bash `run_in_background` — never foreground, never a per-turn `status` poll. Its loop prints a liveness line about every minute (phase, elapsed, alive, budget, findings seen) and self-exits at the terminal phase. Blind engines — greptile and macroscope — stream nothing between launch and the terminal dump: quiet is healthy, `alive=yes` with a counting-down `budget_s` is the health read, and the deadline is the sole timeout; the keepalive engine, coderabbit, additionally converts heartbeat silence past its grace to `stalled`. Terminal phases are `completed|failed|refused|stalled|timed-out|killed` — a terminal receipt short of `completed` names its fault `signature`, the `remedy`, and the engine `exit_code` — and `status --follow --all-live` exits 0 only when every followed round completed.

Bare `status` resolves the single live round, else the highest-numbered on disk; several live rounds refuse `ambiguous` naming them — pass `--round`, `--reviewer`, or `--all-live`. `kill` (same selectors) escalates SIGTERM to SIGKILL over the process group, sweeps detached survivors and macroscope worktrees, and reaps a wedged stalled or timed-out round whose engine still breathes; it refuses only a gather round (`no-process`) and a round whose process group is truly gone (`already-closed`).

`findings --normalize` gates on terminal phase `completed` and refuses an already-sliced round; cross-round dedup runs by default against the latest prior round carrying lane reports, `--dedup-against N` pins the pool, and dropped fingerprints leave after the provenance histogram (`relitigation|refuted_remint|new_work|late_discovery`, stamped against that prior round's ledger) computes over the full set, so relitigation still surfaces while lanes never re-fix adjudicated rows; `scope_misfire` on the receipt flags zero rows over a dirty scope, and an exit-0 zero-comment envelope over a clean scope is ordinary success. Bare `findings` reprints the summary receipt from disk. `gather` takes exactly one of `--all-live` (every open engine round), `--reviewer cr,gt,ms`, or `--rounds 1,2,3`, and every source must be `completed` and normalized.

`slice --lanes N --by folder --balance count|loc` clears stale lane files, stamps round-scoped ids, and emits per-lane manifests carrying the settled-rulings roster. `reconcile` covers all lanes bare (`--all` is the explicit synonym; a named lane plus `--all` refuses). `round` refuses a duplicate close, fails loud on findings without lane reports, and closes a zero-findings round clean. `verify` takes exactly one of `--rule <text> [--path <file>]` (greptile cascade check) or `--round N` (all-surface ledger check).

- [KEEPERS]: fix waves ride the `templates/codex-lane.md` form — up to 12 lanes sliced by folder ownership, one keeper each; fable runs the distill and opus the focused closers.

## [04]-[LANE_CONTRACT]

Fixer-lane doctrine lives in `templates/lane-law.md`; each lane's report is the machine intake `reconcile`, `harvest`, and the reviewer-harvest agent parse, written to `<round-dir>/lane-<letter>-report.json` as the lane's final act:

```json signature
{
  "ledger": [{"id": "", "file": "", "severity": "", "verdict": "fixed|upgraded|pushed-back|already_resolved", "note": ""}],
  "improvements": [{"page": "", "pattern": "", "what": "", "axis": ""}],
  "refuted": [{"claim": "", "evidence": ""}],
  "capability": [],
  "routing": [],
  "uncertain": [],
  "model": "",
  "wall_s": 0.0
}
```

`axis` is fixer-stamped hunt-axis metadata, never inferred; `capability`/`routing`/`uncertain` rows are free-shape JSON the harvest feed reprints.

## [05]-[DISTILL]

Reviewer-harvest owns the distill leg: dispatch it via `Agent(subagent_type: "reviewer-harvest")` under the `templates/harvest-dispatch.md` prompt, and it returns a typed surface ledger. Round dirs sit outside the agent's write territory, so project its landed guards into `<round-dir>/surface-ledger.json` yourself as `[{surface, text, path}]` rows — `surface` an engine name or alias, `text` the guard substring, `path` blank falling to `.coderabbit.yaml` for coderabbit and the repo-wide cascade for greptile, while a macroscope row names its topic file relative to `.macroscope/` — then `verify --round N` proves each row effective in its surface's own oracle.

- [REGISTRY]: `templates/refuted-classes.yaml` rows compile into the claim classifier, the recurrence detector, and the settled-rulings roster sliced into lane manifests; `harvest` proposes new rows in the feed, and a landed row is edited in the yaml, never in the script.
- [RAIL_GAPS]: a rail gap a round exposes lands on the rail's own script and data surfaces.
- [VERIFY]: `verify --round` re-proves each landed guard — a `.coderabbit.yaml` `path_instructions` clause by text, a greptile rule by substring over the resolved `greptile config` output (never by id — org rules re-key to server UUIDs), a macroscope topic file by presence and content.
- [FEED_OUTPUTS]: provenance and corroboration histograms feed review-the-reviewer — a class one engine raises and rounds keep refuting marks that engine's false-positive tendency, and multi-engine corroboration marks high-confidence work.
- [PROPOSALS]: `memory-proposals/` under the round dir carries candidate memory files the orchestrator curates, never the live memory dir; the feed's `[GUARD_INEFFECTIVE]` section names classes recurring despite landed guards — wording failed, harden the owner, never skip as already-owned.

## [06]-[NON_GOALS]

- Rail territory ends at manifests and feeds — fixer dispatch belongs to the orchestrator, which judges slicing, models, and prompts.
- Watchers arm per round and die at terminal; no standing watcher, daemon, or per-event hook.
- Cross-reviewer merge stops at fingerprint dedup and the corroborator record — two engines disagreeing is signal, never noise to reconcile silently.
- `rounds.jsonl` is the health readout and the row-to-row delta the only progress instrument — jsonl and jq, never a dashboard.
