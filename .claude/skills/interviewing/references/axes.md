# [AXES]

The interrogation-axis catalog: where unknown unknowns hide and how each is hunted. Every grounding pass selects the axes the request touches, runs each axis's probe, verifies every candidate on disk, and records survivors as confrontation-set entries. An axis that comes back clean is recorded clean; absence of findings is a finding.

Each axis carries one card: Definition (the pathology), Probe (what to read or sweep, phrased as a leg a delegation runs over a subtree or a seam spine), Question (the shape that confronts the user with a named anchor), Evidence (what confirms a hit before it enters a question). The section label is the axis token — it names the axis in confrontation-set entries and in blindspot-ledger leaders, and the token is the axis identity every confrontation row and ledger leader binds; the two-digit ordinal orders the reading families alone, so a new axis joins its family, takes an ordinal, and reorders the tail without drifting a single reference.

The catalog reads in families — ownership; identity, inverse, and seam; topology and grain; time and growth; custody and proof; premise and omission — and a selection pass touches the family before the axis; the cards run in that order. A cross-cutting set hunts across owners rather than inside one — CONSERVATION, IDENTITY, ROUNDTRIP, TOUCH_POINT, TEMPORAL, and LAYERING — so a single-subtree probe records them clean while a split-brain hides across the seam; the scaling law carries them on seam-spine legs.

[CONFRONTATION_SET] — The grounding product is a flat entry list, one row per verified finding; a cross-owner finding carries the mirror anchor beside the primary:

```markdown
- [<AXIS>]: <path>:<line> — <observed-fact-in-one-clause>
- [<AXIS>]: <path>:<line> ⇄ <path>:<line> — <the-fact-and-how-the-two-ends-diverge>
```

[SCALING] — A corpus past one reading budget partitions on two dimensions at once. Subtree legs at unit grain carry the local axes over one folder subtree; seam-spine legs carry the cross-cutting axes along one identity, wire, persistence, runtime, or host spine end to end, because a split-brain only shows where the probe crosses owners. Each leg reads its slice's index docs in full, samples implementation pages, and returns confrontation rows — with the mirror anchor where its axis is cross-cutting — plus its clean-axis list. The interviewer merges, dedupes by anchor pair, and re-verifies any row it embeds in a question. A cross-cutting axis assigned only to subtree legs is a partition defect: it reports clean while the seam it never traversed hides the finding.

## [01]-[STRUCTURE]

- Definition: Architecture fighting itself — parallel near-duplicate rails, one concern owned twice, split-brain siblings solving one concept differently, or a single owner's row set bloated past the point where a repeated column belongs on a higher axis.
- Probe: Search for sibling surfaces sharing a concept vocabulary and compare their case sets; sweep for duplicate-marker and retirement-scar language; flag any row family whose repeated column is a disguised second axis; a leg returns each duplicate pair and each uncompressed row family with anchors.
- Question: `<surface-a>:<line>` and `<surface-b>:<line>` both own `<concern>` — which is canonical and what folds the other in; or `<owner>`'s rows repeat `<column>` — which higher axis compresses them.
- Evidence: Two verified surfaces carrying one concern with divergent shapes, or a row family whose column set is a latent axis.

## [02]-[CONSERVATION]

- Definition: A fact whose one canonical rail is multiplied or merged — one source fact minted twice, one delta landed twice, one event forked into several authoritative truths (receipt, fault, op-log, CRDT op, artifact frame, trace, UI evidence), or two distinct typed channels collapsed into a lossy generic one; a participant minting what its posture admits only to decode, reproduce, or additively extend.
- Probe: Trace one fact through mint, land, project, transfer, decode and count authoritative copies; classify each copy's role — mint, projection, evidence, product, wire proposal, query frame — a second copy in one role is the violation, distinct roles over one mint are not; name each participant's posture (decode/reproduce/additive/companion) and flag any that exceeds it; sweep fault and receipt families for a shared-envelope merge; a leg carries this over one seam spine, never one subtree.
- Question: `<fact>` appears at `<anchor-a>` and `<anchor-b>` — which is the one authoritative rail, which are derived projections, and which participant mints what it may only decode.
- Evidence: One fact with two mint sites, one event carried as parallel authoritative truths, or two typed channels folded into a generic third.

## [03]-[REFUSAL]

- Definition: A surface owning a capability it must explicitly refuse to stay coherent — the seductive over-reach where a consumer absorbs an upstream owner's truth: the execution layer wanting domain semantics, the view wanting durable state, the derived producer wanting the canonical vocabulary, the importer minting catalogue identity.
- Probe: For each owner name every capability it is closest to absorbing — the adjacent one and any authoritative concern several strata down — and check whether the refusal is stated as owned law; sweep for a surface holding a second copy of any deeper owner's authoritative concern; a leg returns each unstated refusal and each absorbed concern with anchors.
- Question: `<surface>:<line>` is one step — or several strata — from owning `<concern>` a deeper owner mints — is the refusal stated as law, or has the surface already absorbed it.
- Evidence: An attractive neighbor capability with no stated refusal, or a surface holding a second copy of a concern a deeper owner mints.

## [04]-[CAPABILITY_WEAKNESS]

- Definition: An owner modeling a thin slice of its concept — few fields or cases where the domain is rich — or an index claiming capability its pages do not carry.
- Probe: Sample each owner against its concept's full attribute and state space; cross-check every index-tier capability claim against the page and evidence catalog that must carry it; a leg returns each claim-to-carriage mismatch with both anchors.
- Question: `<index>:<line>` claims `<capability>`; `<page>:<line>` carries `<n>` of the `<m>` the concept holds — which missing arms are refused by design and which are gaps.
- Evidence: A claim-to-carriage mismatch anchored on both sides, or an owner field set visibly below its concept's known shape.

## [05]-[IDENTITY]

- Definition: Two keys that read as equal but are not comparable — a second hasher, seed, byte order, tolerance grid, sort order, format tag, or tenant partition; a key content-derived on one side and precomputed on the other, or id-inclusive on one side and id-exclusive on the other.
- Probe: For every identity, snapshot, artifact, cache, and wire key name the exact bytes hashed and the seed, order, tolerance, and folded policy or tenant dimensions; compare every pair that must be equal across a loop, and sweep every sibling addressing key minted beside a content key — CDN row, cache row, residency cell — that never enters that loop yet shadows identity; a spine leg carries the key algebra across strata and returns each divergent pair and each shadowing sibling key.
- Question: `<key-a>:<line>` and `<key-b>:<line>` are treated as equal — which exact bytes, seed, and order each hashes, and where the branch proves they cannot diverge.
- Evidence: Two keys compared as equal whose mint regimes — hasher, seed, order, tolerance, id-inclusion, partition — differ.

## [06]-[ROUNDTRIP]

- Definition: A transform with a forward arm and no proven inverse, or an inverse that is not the forward arm's mirror — import without export parity, encode without decode, mint without verify, stamp without apply, raise without lower, a decode-transform-emit-reimport loop that does not return the canonical input.
- Probe: For each transform locate its inverse arm and pair their probes; run the full loop over a maximal instance that populates every optional arm, oneof branch, and foreign-field residue rather than the minimal canonical one, and compare the reimported result to the source; a leg returns each transform whose inverse is absent, asymmetric, or unproven, and each optional arm the inverse drops.
- Question: `<transform>:<line>` lowers `<concept>` — which arm raises it, and does a full loop return the canonical bytes or drift.
- Evidence: A forward transform with no inverse arm, or a loop whose reimported result diverges from its source.

## [07]-[TOUCH_POINT]

- Definition: Incomplete or divergent seams — a contract declared on one side only, a consumer without a provider page, an evidence catalog referenced but absent or stale, or two endpoints that both exist yet record a different band, descriptor, kind, or shape.
- Probe: For every declared seam edge open both endpoints and verify the reciprocal declaration and that both record the same band, descriptor, kind, and shape; for every producer with more than one consumer open each consumer and verify they read one decoded shape, not each a local decode; for every capability claim naming a dependency verify the adjacent evidence entry exists and matches; a leg returns each one-sided or drifted seam and each shared producer read two ways, with both anchors.
- Question: `<side-a>:<line>` declares the seam; `<side-b>` does not know it exists, or records `<other-shape>` — which side owns the contract and what lands or realigns the missing half.
- Evidence: A one-sided declaration, or a reciprocal pair whose recorded shapes diverge, verified by opening both ends.

## [08]-[FOLDER_TOPOLOGY]

- Definition: Structure pathologies of the tree itself — one-folder-one-file chains, over-nesting with single children, one concern scattered across many small siblings, flat dumps past navigability.
- Probe: Sweep the tree for single-child directories and single-file folders; count files per directory and flag flat sets past the point where naming convention is the only index; a leg returns the counts and chains for its subtree.
- Question: `<folder>` holds one file its parent map already names — which rule decides folder against section, and what does the extra level buy.
- Evidence: The tree listing itself — counts and chains verified by a fresh sweep.

## [09]-[NAMING]

- Definition: A name carrying one or two semantic values where the content carries many — generic tokens, tautological file names, names that do not predict content.
- Probe: Sweep the generic-name roster (`core`, `common`, `utils`, `helpers`, `base`, `shared`, `data`, `info`, `manager`, `index`, `misc`, `plan`) and compare each hit's name to its first owner sentence; a leg returns each name-to-content mismatch with the charter anchor.
- Question: An agent hunting `<capability>` reads the tree — does `<name>` ever get chosen, and what name predicts the content it hides.
- Evidence: A name-to-content mismatch verified by reading the file's own charter line.

## [10]-[APPROACH]

- Definition: A design fighting the grain — hand-rolling what an admitted dependency owns, a hand-maintained list shadowing what a generator owns exhaustively, an unusual mechanism where the ecosystem has a native one, entry proliferation or a composition root that scripts satisfaction over one polymorphic surface.
- Probe: For each mechanism name the admitted dependency or generator that owns the concern; sweep for multiple entry points over one aspect and for hand-lists parallel to a generated union, mapper, descriptor, or equality owner; a leg returns each hand-rolled span with the owning member.
- Question: `<surface>:<line>` hand-carries `<concern>` that `<dependency-or-generator>` owns — what does the local mechanism add that the native one refuses.
- Evidence: A verified dependency or generator member covering the hand-rolled ground, or three entry names over one declared aspect.

## [11]-[LAYERING]

- Definition: Construction, import, or altitude order fighting the declared strata — a code-fence import against the seam-ledger direction, a capability built before the owner it depends on lands, a transitive chain leaking an interior across two hops, or one page mixing branch-law, folder-seam, and spec-mechanism altitude into contradictory law.
- Probe: For each declared strata edge verify that code-fence imports and construction order run the same direction; trace second-order chains for an interior leak; check each page for a single altitude; a leg returns each back-edge, out-of-order build, transitive leak, and altitude-mixed page.
- Question: `<owner-a>:<line>` imports or builds against `<owner-b>` — does that edge match the declared strata direction, and which transitive hop leaks an interior.
- Evidence: An import or construction edge against the declared direction, a transitive interior leak, or a page carrying two altitudes as one law.

## [12]-[EXTENDABILITY]

- Definition: Growth the domain will demand that no surface reserves — the next case, modality, provider, or scale step lands as a break instead of a row.
- Probe: Read the owner's case set, name the domain's cases beyond it, and test each deferred or growth marker for a real extension operator; a leg sweeps its subtree's owners and returns each case set that names fewer arms than its concept carries.
- Question: `<owner>:<line>` carries `<n>` arms; the domain carries `<future-case>` — which row, case, or policy value absorbs it, and what breaks on arrival.
- Evidence: An extension scenario with no landing surface, or a growth note with no operator behind it.

## [13]-[LONG_TERM]

- Definition: Lifecycle ground no page reserves — versioning, migration, deprecation, retention, multi-host reach — or a retirement that orphans its mirrors, arriving later as a surface break.
- Probe: For each owner walk the lifecycle stages its concept carries and mark which have a reserved surface; sweep closed-count declarations for missing escape paths; for each removable surface name every mirror endpoint that must retire with it; a leg returns each unreserved stage and each orphaning deletion.
- Question: When `<lifecycle-event>` arrives, which surface absorbs it and what is the reserved path for cases outside the current set; when `<surface>` retires, which mirror endpoints retire with it.
- Evidence: A lifecycle stage with no owner anywhere in the corpus, or a deletion whose mirror endpoints have no coordinated retirement.

## [14]-[TEMPORAL]

- Definition: Correctness that holds only at the current instant — a replay window, session epoch, HLC tie-break, stale cache read, retention or GC pass, or partial-peer rollout that corrupts an older AS-OF cut, accepts cross-epoch live deltas into a cold-loaded state, or drops the unknown-field residue an old reader still needs.
- Probe: For each durable surface name its time-bearing reads — replay, cold-load, AS-OF, stale-cache, residue during rollout — and test each against a point-in-time cut rather than the current head; drive a cross-epoch write — a live delta minted at one epoch into a state cold-loaded at another — and prove the surface reconciles or rejects, never silently applies; a spine leg carries time-travel across the persistence and sync seams and returns each failing cut and each silently admitted delta.
- Question: At `<past-cut>` the surface at `<anchor>` reads `<value>` — does retention, GC, epoch, or residue keep that cut correct, or does only the current head hold.
- Evidence: An older cut, replay window, or rehydrated epoch that diverges under retention, GC, cross-epoch delta, or dropped residue.

## [15]-[CUSTODY]

- Definition: A host, runtime, or residency fact with no single owner under concurrent mounts — credentials, host lifecycle, recipe execution, transport, object-store access, or byte residency (memory, cache, object store, artifact index, deploy root) held ambiguously; a runtime-conditioned import leaking into a surface the wrong condition serves.
- Probe: For each operational fact name the one owner that admits it and refuse the rest; enumerate every host that mounts the model concurrently and the byte residency at each hop; sweep exports and platform conditions for a node-only import in a browser-safe owner or its inverse; a leg returns each ambiguous custody and each condition leak.
- Question: When `<host-a>` and `<host-b>` mount `<model>` at once, which owner holds `<credential-or-lifecycle-or-residency>`, and which condition-scoped import crossed into the wrong surface.
- Evidence: An operational fact claimed by two owners or none, a byte with no named residency owner, or a runtime-conditioned import in the wrong-condition surface.

## [16]-[PROOF]

- Definition: A claim with no executable guard behind it, or guards that disagree with no ranked precedence — an owner named correctly but proven by prose, a seam with no drift gate or fixture, a capability claim with no `.api` catalogue or generated artifact, a realized roster and a runtime probe asserting different facts.
- Probe: For each seam and capability claim name the guard that proves it — drift gate, fixture, `.api` catalogue, generated artifact, runtime probe, realized roster — rank the sources by declared precedence before any run, and verify every pair of guards over one claim keys the same instance, epoch, and profile rather than each reporting green over a different subject; a leg returns each unguarded claim, each source conflict, and each matching-green pair bound to divergent subjects.
- Question: `<claim>:<line>` names the right owner — which executable guard proves it, and when `<source-a>` and `<source-b>` disagree which outranks.
- Evidence: A seam or capability claim with no guard, or two proof sources asserting different facts with no stated precedence.

## [17]-[FRAMING]

- Definition: A request naming a solution or sub-problem whose motivating problem the territory contradicts or serves better elsewhere — the stated ask is a means already chosen, the goal behind it unstated, and the unit of success undefined.
- Probe: Extract the request's implied goal and trace the pain to its origin — the episode, cost, or constraint that produced the ask; check whether the corpus already serves that goal by another surface and whether the ask's success leaves the pain standing; a leg returns each ask whose motivating pain a different change resolves more directly.
- Question: The request asks for `<solution>`; the pain anchors at `<anchor>` — does `<solution>` retire that pain, or does `<other-change>` retire it at lower cost, and which outcome is the unit of success.
- Evidence: A motivating pain the stated ask leaves standing, or a corpus surface that already serves the extracted goal.

## [18]-[SCOPE_NAIVETY]

- Definition: Goals assuming without stating an external precondition outside the design's control — an environment always present, a single user, a happy path, an unnamed dependency's availability.
- Probe: For each goal sentence extract what must be true for it to hold and sweep for external dependencies carried by convention rather than declared contract; a leg returns each must-be-true condition with no declared owner.
- Question: `<goal>` holds only while `<condition>` does — what is the story when it fails.
- Evidence: A must-be-true condition with no declared owner, fallback, or refusal.

## [19]-[ASSUMPTION]

- Definition: Unstated premises internal to the design's own reasoning, warranted or not by evidence the author can produce on request — the roster a key-assumptions check produces, ranked by importance against evidence.
- Probe: Write each settled line, articulate its stated and unstated premises, and place each on the importance-by-evidence quadrant; a leg returns the high-importance low-evidence corner as its row set.
- Question: The design rests on `<premise>` — what evidence carries it, and does the judgment survive its failure.
- Evidence: A load-bearing premise whose supporting evidence cannot be produced on request.

## [20]-[COUNTERFACTUAL]

- Definition: The unexamined inverse — what failure looks like with the goal met, a surface success (a render, a green test, a passing demo) reached off the owned rail, which trigger chains nobody mapped.
- Probe: Take each settled judgment and each success signal, assume the negation or the bypass happened, build the backward pathway, and name the observables that mark each stage; a leg returns each pathway with the constraint that fails to block it.
- Question: `<goal>` is met and the result still counts as failure — what happened, and which owned rail did the success signal bypass.
- Evidence: A plausible pathway to the negated outcome that no stated constraint blocks, or a success signal that clears while a canonical path is skipped.

## [21]-[OVERSIGHT]

- Definition: Skipped stages and unnamed parties — teardown, recovery, observation, migration nobody mentions; consumers the request never names.
- Probe: Walk the stage roster (create, operate, observe, recover, migrate, retire) against the request and enumerate consumers from the seam registers, diffing against the named set; a leg returns each absent stage and each unnamed consumer with its register anchor.
- Question: `<stage>` is absent from the request — refused or forgotten; `<consumer>:<line>` reads `<seam>` and the request never names it.
- Evidence: A stage or consumer present in the corpus's own registers that the request omits.
