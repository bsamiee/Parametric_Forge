# [EVALS]

A skill's value is measured, never assumed, along exactly two axes: trigger — the skill loads on the tasks it owns and stays silent on its neighbors — and adherence — the loaded body changes output relative to a run without it. Both run before a bundle ships and after every material revision; the suite is authored before the body it measures, so a body rule ships only after an adherence run proves it changes output, and a skill without an eval history is a hypothesis wearing a description.

## [01]-[TRIGGER_EVALS]

- [QUERY_SETS]: Build a must-fire set and a must-not-fire set of realistic task phrasings — around twenty per side — drawn from how tasks actually arrive, not from the description's own vocabulary. The must-not-fire set carries near-misses: prompts naming an adjacent deliverable a sibling owns, and ordinary-working-day prompts with no domain noun.
- [HOLDOUT]: When iterating the description against miss rates, the query set splits: the description is tuned against one half and judged against the held-out half. A description tuned and judged on the same queries memorizes phrasings instead of learning the boundary.
- [ATTRIBUTION]: A must-fire miss is a starved or buried discriminant — fixed in the description's first clause. A must-not-fire hit is a boundary defect — fixed by a sharper discriminant or an added refusal, on both colliding skills. Neither is ever fixed in the body: the body is invisible to selection.
- [ACCUMULATION]: Every trigger miss observed in real work becomes a permanent query row; the sets only grow.

## [02]-[ADHERENCE_EVALS]

- [PAIRED_RUNS]: Each task runs twice under identical conditions — once with the skill installed, once baseline — launched together so timing and environment match. Revising an existing skill snapshots the prior version as the baseline.
- [BLIND_COMPARISON]: A judge scores both outputs against a task-specific rubric without knowing which run carried the skill, and is pushed off ties. Blindness is what separates measured value from confirmation.
- [UNBLINDING]: After the verdict, analysis unblinds and reads both transcripts to attribute the difference to specific instructions — which rule the winner obeyed, which the loser lacked or misread. Attribution, not the score, is what drives the next revision.
- [DEAD_LAW]: A body rule that changes no output across the suite is dead weight and is deleted; the suite is the only defensible census of which lines earn their context.

## [03]-[GRADERS]

- [DETERMINISTIC_FIRST]: Structure checks, gates, exit codes, and state assertions grade everything they can reach; rubric judgment covers only what determinism cannot.
- [RUBRIC_ISOLATION]: A model grader scores one dimension per rubric, calibrated against human verdicts on a sample, with partial credit and an admissible abstain verdict — a grader forced to answer fabricates.
- [ARTIFACT_NOT_PATH]: Grading binds to what the run produced, never to the tool-call sequence that produced it; a sequence check fails valid approaches the eval author did not anticipate.
- [TASK_QUALITY]: A task is admissible when two domain experts independently reach the same verdict on any output, and a reference solution proves both solvability and grader correctness.
- [BALANCE]: The suite carries positive and negative cases in both families; a one-sided suite optimizes one-sidedly — a suite of only must-fire queries breeds an over-triggering description.

## [04]-[TRIALS_AND_LIFECYCLE]

- [CONSISTENCY]: Runs are non-deterministic, so verdicts aggregate over trials: any-success measures whether the skill unlocks a capability at all; every-success measures whether it holds under repetition. The deliverable's consistency requirement picks the metric.
- [GRADUATION]: A capability suite starts hard with low pass rates and marks the frontier; once passing is routine it graduates into the regression suite, which stays near full marks and exists to catch decay.
- [SEEDING]: The first suite is twenty to fifty tasks harvested from real failures and manual checks, prioritized by impact — never synthetic tasks invented to pass.
- [TRANSCRIPTS]: Failures are read, not counted. The transcript decides whether a miss is trigger, routing, freedom mismatch, or law, and routes the fix to the description, a route row, a band change, or a body rule. A saturated task teaches nothing and retires.

## [05]-[TOOLING]

- [ROLE_SPLIT]: Grading, comparison, and attribution run as separate fresh-context agents — a grader verifying each run against its task's expectations, a blind comparator ranking the pair, an unblinded analyzer attributing the difference to specific instructions. One agent holding every role leaks run identity into the verdict.
- [DURABLE_SUITE]: Query sets, verdicts, transcripts, and revision history persist as typed JSON beside the bundle under iteration; a revision measures against recorded baselines, and the suite outlives the session that built it.
- [ISOLATION]: Each trial runs in a clean environment — no shared state, cached artifacts, or history leaking between the paired runs; an environment-correlated failure indicts the harness, never the skill.
