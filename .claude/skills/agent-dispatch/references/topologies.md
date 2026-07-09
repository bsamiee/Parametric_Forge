# [TOPOLOGIES]

Topology is the shape of result flow, fixed before the first spawn: it decides who consolidates, what each worker returns, and when the run stops. The wrong shape wastes tokens symmetrically — a panel on divisible work debates instead of dividing, a star on contested judgment averages instead of arguing.

## [01]-[SHAPES]

| [INDEX] | [SHAPE]         | [FLOW]                                                      | [SELECT_WHEN]                                                          |
| :-----: | :-------------- | :---------------------------------------------------------- | :--------------------------------------------------------------------- |
|  [01]   | Star            | Fan out disjoint lenses, one consolidator merges            | Independent territories, breadth-heavy audit or research               |
|  [02]   | Pipeline        | Stages transform an artifact under explicit contracts       | Stable ordering; each stage verifies the previous stage's output       |
|  [03]   | Panel           | Independent verdicts on one question, then adjudication     | Ambiguous or high-stakes judgment where disagreement finds blind spots |
|  [04]   | Tournament      | N candidates, blind pairwise comparison, unblinded analysis | Taste-heavy artifacts; comparison grades better than absolute scores   |
|  [05]   | Generate-filter | Cheap generators flood, a strict gate admits                | Search problems where candidate cost is low and the gate is sharp      |
|  [06]   | Loop            | Work, verify, repeat until an external check passes         | Convergent work with a deterministic done-signal                       |

## [02]-[CONSOLIDATION]

Raw parallel reports are not a result. The consolidator resolves conflicts between workers, deduplicates overlapping findings, ranks by severity or value, and emits one action plan — a distinct worker with its own contract, never an afterthought in the dispatcher's context. Panel adjudication weighs argument quality over vote counts, since worker diversity, not worker count, is what exposes blind spots; a tournament's comparator stays blind to which variant produced which output, and the unblinded pass afterward extracts why the winner won.

## [03]-[OWNERSHIP]

Parallel dispatch requires disjoint write territories: no two concurrent workers touch one file, and when the decomposition cannot guarantee that, the work is re-cut by domain or endpoint, run through `isolation: worktree`, or serialized. Read overlap is free; write overlap is a defect that surfaces as silent clobbering. Sequential dispatch is the default whenever stages share files, dependencies chain, or scope is still forming.

## [04]-[LOOPS]

A loop's stop condition is externally measurable — a passing suite, an empty queue, a zero lint count, a merged PR — never the worker's own judgment of doneness, which stops early under context pressure and late under vague specs.

```markdown rejected
Keep improving the test suite until it is in good shape.
```

```markdown accepted
Loop until `pnpm vitest run` exits 0 with coverage at or above 90%; cap at six rounds;
two consecutive rounds without a new fix end the run as stuck, returning the evidence.
```

Loop law:

- [CAP]: every loop carries a maximum iteration count beside its stop condition; the pair prevents both runaway and premature exit.
- [PROGRESS]: two consecutive rounds without new findings or fixes end the run as converged-or-stuck; a stuck verdict returns evidence, not retries.
- [VERIFY]: the checker is independent of the producer — a fresh-context reviewer, a deterministic gate, or a stop-hook that blocks completion until validation passes. Self-grading inflates.
- [CHECKPOINT]: long loops externalize state to disk each round so a dead run resumes from its last artifact instead of its first prompt.
- [TRIGGER]: recurring loops ride `/loop` for interval work and scheduled routines for calendar work; event triggers beat clock polling wherever the source system emits one.
