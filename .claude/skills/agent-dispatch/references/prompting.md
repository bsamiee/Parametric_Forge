# [PROMPTING]

Delegation quality is prompt quality: a fresh worker knows nothing the prompt omits, and the dominant field failure is the vague dispatch — a worker told to "fix authentication" invents scope, while a worker handed territory, constraints, and an output contract executes.

## [01]-[STARTUP_CONTEXT]

A non-fork worker's opening context is exactly: its own system prompt (the definition body), the delegation message the dispatcher writes, the full memory hierarchy the parent loaded, a git status snapshot from parent session start, and any preloaded skills. It sees no parent conversation, no prior file reads, no invoked skills. Explore and Plan skip the memory hierarchy and git snapshot entirely, so a rule that must bind them — an ignored directory, a banned path — is restated inside the delegation prompt itself.

## [02]-[CONTRACT]

Every delegation prompt carries five fields; a missing field is filled by the worker's imagination.

- [01]-[OBJECTIVE]: The single outcome, stated as a verifiable end state, never an activity.
- [02]-[TERRITORY]: Exact files, directories, symbols, or sources in scope, and the tools or MCP servers the worker leans on where the default set is wrong.
- [03]-[EXCLUSIONS]: Adjacent surfaces the worker must not touch, and the boundary with sibling workers.
- [04]-[CONTRACT]: The return shape — schema, receipt fields, report sections, evidence requirements.
- [05]-[ACCEPTANCE]: The externally checkable signal that the work is done — passing gate, count, artifact.

Workers cannot ask questions mid-run, so ambiguity is resolved before dispatch or delegated as an explicit investigation step inside the objective. Constraints that exist in the parent's head — register, conventions, prior decisions — travel in the prompt or die at the boundary.

```markdown rejected
Fix the flaky auth tests. Be thorough and report back.
```

```markdown accepted
OBJECTIVE: `pnpm vitest run tests/auth` passes five consecutive runs.
TERRITORY: `tests/auth/**` and `src/auth/session.ts`; the flake reproduces with
`pnpm vitest run tests/auth --retry=0` — `refresh rotates token` fails roughly one run in three.
EXCLUSIONS: `src/auth/oauth/**` belongs to a concurrent worker; public API signatures stay unchanged.
CONTRACT: return `{cause, filesChanged, verification}` — `cause` names the race or fixture defect
with file-line anchors, `verification` the exact commands run.
ACCEPTANCE: five consecutive green runs, zero skipped tests.
```

## [03]-[RECEIPTS]

- [LABEL]: every spawn carries a distinct label naming its lens; a fan-out of unlabeled workers is unreviewable in any progress surface.
- [RECEIPT]: the worker's final message is the only thing that returns, so the contract pins its shape — a `{path, summary}` receipt with the product written to disk makes any stage re-enterable at zero cache dependence and keeps bulk out of the parent.
- [SCHEMA]: when the parent computes on the result, the contract is a typed schema, never prose the parent re-parses.
- [EVIDENCE]: audit and review workers return claims with file-line anchors and a residual-risk section — what was not checked and why — so the consolidator ranks instead of re-verifying.
- [VERBATIM]: a parent summarizes worker output by default; when the raw report must survive, the parent's own instructions say to pass it through untouched.

## [04]-[AUGMENTATION]

The dispatcher rewrites rough intent into the scoped task before spawning: a report of "the auth bug" becomes a prompt naming the failing flow, the candidate files, the observed log lines, and the reproduction command. Query augmentation is the dispatcher's job precisely because the dispatcher holds the conversation the worker will never see — every dispatch is a compression of parent context into worker-sufficient form.

## [05]-[META_DELEGATION]

A worker delegates further only when its own task splits and the intermediate noise has no value upstream. The dispatcher authorizes this explicitly: grant `Agent` in the worker's tools, then write the split policy into its prompt — the decomposition axis, what each child owns, each child's return contract, and the depth budget remaining under the five-level ceiling. A worker left to improvise delegation either never spawns (losing the isolation win) or spawns ungoverned children whose reports it cannot consolidate. Throwaway grandchildren absorb search noise and return verdicts; the specialist parent keeps its window for synthesis.

## [06]-[TEAMMATES]

A teammate spawn prompt obeys the same contract with one tightening: the lead's conversation history never transfers, so acceptance criteria, file ownership, and inter-teammate boundaries are spelled out in full. Each teammate owns a disjoint file territory; a shared file is a design error repaired by re-decomposition, not coordination. Task granularity lands at self-contained units — five or six per teammate — so progress is observable and reassignment has seams.
