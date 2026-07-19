# [THREAD_RUN]

One complete descent at composed scale: a solution-shaped request, the grounding that re-frames it, one thread planned to its ruling and driven through its strata, and the record that lands. Every stage instantiates the law it names — the FRAMING re-route, the branch-planned thread, the push held by anchor, the decision-record contract — and the terminal record composes through the html-studio decision-doc type with its pick returned as a receipt.

## [01]-[REQUEST]

```text
Add a cache in front of the render pipeline — rebuilds are too slow.
```

That request names a mechanism, not a problem: a cache is a means already chosen, the goal behind it unstated, the unit of success undefined. Grounding runs before any question.

## [02]-[GROUNDING]

Axes selected by the request — FRAMING, CONSERVATION, IDENTITY, APPROACH, TEMPORAL — probed over the pipeline subtree and the persistence seam. Grounding yields the confrontation set:

```markdown generated
- [FRAMING]: <unit>/pipeline/render.md:41 — render outputs are already content-keyed through the artifact index; the asked-for cache exists
- [FRAMING]: <unit>/pipeline/fonts.md:12 — font subsetting re-runs whole on every build, keyed by nothing; stage timings put it at 41 of 56 cold seconds
- [CONSERVATION]: <unit>/pipeline/render.md:63 ⇄ <unit>/deploy/publish.md:27 — render receipts mint at both ends; routed to its own tracked card
- [CLEAN]: IDENTITY, TEMPORAL
```

## [03]-[RE_FRAME]

FRAMING rows indict the request: the asked-for cache exists, and the pain — cold-rebuild wall time — anchors at the one un-keyed stage the cache never touches. Its extracted goal replaces the ask as the interview's subject, and the ask enters the fan as one candidate resolution among its rivals.

```markdown generated
[CONSTRAINT] Unit of success: cold-rebuild wall time, not cache presence.
[CONSTRAINT] One identity rail — the artifact index is the only content-key regime (house law, recorded, not asked).
[CANDIDATE] The original ask survives as option: a front cache layer.
```

## [04]-[THREAD_PLAN]

One thread roots at the load-bearing fork; both branches carry their premised follow-ups before the first question is asked.

```text
Root: which stage owns the rebuild cost the unit of success measures? [decides the whole line]
  - a) the un-keyed subsetter (per the anchor) → 2a: which keying regime absorbs it?
      - a1) the existing artifact index → 3: what must become explicit for the stage to key?
      - a2) a new regime (front cache, tree memo) → 3': which constraint kills a second rail?
  - b) the anchor misleads; cost is elsewhere → re-ground against the stage timings before any design question
Terminal schema: one ruling naming the owner surface that changes, with its confirmation signal.
```

## [05]-[DESCENT]

```text
1. <unit>/pipeline/fonts.md:12 — subsetting re-runs whole on every build and carries 41 of 56 cold
   seconds. Does the rebuild-cost thread root here, or does a measurement you hold contradict the anchor?
   → "It's the fonts, but the index lookup is probably slow too once everything is keyed."
   [ruling: root confirmed at the subsetter — fact, anchored]
   [push held: the lookup claim is future-tense and unanchored; recorded as reported belief, not a
    second root — a forcing fact would be a profile showing lookup time, and none exists on disk]

2. (premise: the subsetter owns the cost) Three resolutions survive the constraint frame; each names
   its cost in the same units — keying regimes added, stages keyed:
   - a) Front cache layer — the ask as stated; 1 new regime, 0 stages keyed; a miss re-runs the subsetter.
   - b) Key the subsetter into the artifact index — 0 new regimes, 1 stage keyed; one migration making
     the glyph set an explicit input.
   - c) Whole-tree memo — 1 new regime at tree grain; one changed page re-renders everything.
   Which regime does the identity-rail constraint admit?
   → b. [ruling: the index absorbs the stage — inference from the one-rail constraint, premises named]

3. (premise: the subsetter keys into the index) The stage reads ambient state today. What must become
   an explicit input for its key to be deterministic?
   → "Font bytes and the glyph set; nothing else feeds it."
   [ruling: key = font bytes + explicit glyph set — assumption until the environment-font sweep runs;
    invalidating condition recorded]
```

Descent terminates: the next question detects no new gap. Stratum 2's rejected arms carry their reopen conditions into the record; the stratum 1 reported belief becomes option (a)'s reopen condition — the profile that revives it.

## [06]-[RECORD]

```markdown generated
- [01]-[ACCEPTED]: Rebuild latency ownership
    - Context: <unit>/pipeline/fonts.md:12 — font subsetting re-runs whole on every build and carries
      41 of 56 cold seconds; render outputs are already content-keyed at <unit>/pipeline/render.md:41,
      so the requested cache exists and the cost anchors at the one un-keyed stage.
    - Drivers: One identity rail; cold-rebuild wall time as the unit of success; no environment reads
      inside a keyed stage.
    - Options: front cache layer | key the subsetter into the index | whole-tree memo
    - Ruling: Font subsetting joins the artifact index as a content-keyed stage, keyed on font bytes
      plus the explicit glyph set.
    - Consequence: The index stays the one identity rail; a no-change rebuild reuses every stage, and
      the subsetter's inputs become declared contract instead of ambient state.
    - Confirmation: A no-change rebuild completes without re-running the subsetter and cold wall time
      drops below the render-only floor.
    - Rejected: front cache layer — a second keying regime beside the index, and a miss still re-runs
      the subsetter; reopens when profiling shows the index lookup itself dominating a fully keyed
      build. whole-tree memo — tree-grain keys re-render everything on one changed page; reopens when
      the unit's page count drops to where whole-tree grain is indistinguishable from stage grain.
    - Premises: [FACT] <unit>/pipeline/fonts.md:12 — the stage re-runs whole, keyed by nothing.
      [ASSUMPTION] subsetter inputs are deterministic once the glyph set is explicit — invalidated if
      the subsetter reads environment fonts, which re-opens the custody question.
```

## [07]-[LANDING]

Three inspectable facts complete the landing.

- Record composes as its html-studio decision-doc page — constraint frame, option grid with per-option verdicts and steal chips, weight-declared scoring matrix, ruling with marked premises, rejected options with reopen conditions — gated and rendered under both themes, homed under the repo's naming law as `decision-record.render-pipeline.rebuild-latency.html`.
- Served, the page returns the reader's pick as one receipt — pick `o2`, `o1`/`o3` rejected, the tree-digest short-circuit stolen from `o3` as a keyed fast path — and the receipt's verdicts face the same challenge as spoken answers before the record seals.
- Fold-back orders rulings by tweak pressure, decisions before mechanics:

```text
Bind these rulings as input: (1) the artifact index is the only content-key regime — no front cache,
no tree memo; reopen conditions in the record. (2) Font subsetting becomes a content-keyed stage of
the index, keyed on font bytes plus an explicit glyph set; verify the stage reads no environment
fonts before keying, and fail the build loudly if it does. (3) Fold the tree-digest short-circuit in
as a fast path over the same keys, never a second regime. Confirmation gate: a no-change rebuild
skips the subsetter and cold wall time lands below the render-only floor.
```
