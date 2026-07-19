# [ARTIFACT_CRAFT]

A durable artifact seals a ruling for a future session to consult as law; an instance that hedges its ruling, seals a decision no thread forced, drops a reopen condition, collides two entries on one id, fakes a multi-tier fan, strands a finding with no landing surface, leaks a plan into a horizon, asserts a gap by assumption, or lets its projection fence drift from its rows fails the cold-read seal — now or a year later. Each entry names one content defect across the five durable kinds under the fixed Detection / Rejected / Accepted / Reason / Reframe card, grouped by the kind it strikes; the Rejected and Accepted bodies are conformant fragments in each kind's leader and field grammar, the content the rendered page carries whatever its form.

## [01]-[HEDGED_RULING]

A decision record's Ruling field carries a preference weighing options instead of the single owning sentence the record exists to seal.

- Detection: A `Ruling` that hedges — a comparative, a conditional, an option still weighed — leaving the downstream author to re-litigate the decision the record exists to close.
- Rejected:
    ```markdown rejected
    - [07]-[ACCEPTED]: Graph carrier ownership
        - Context: Three backends sit behind a string union no type-checker resolves.
        - Options: single owner | per-backend owner
        - Ruling: A single owner is probably cleaner, though a per-backend split could also work depending on the algorithm set.
    ```
- Accepted:
    ```markdown accepted
    - [07]-[ACCEPTED]: Graph carrier ownership
        - Context: Three backends sit behind a string union no type-checker resolves; the third arm is GPL.
        - Drivers: Strict-typing law; GPL isolation; algorithm coverage.
        - Options: single tagged owner | per-backend owner
        - Ruling: `GraphCarrier` is one tagged-union owner; each backend is a resolvable tag and the GPL backend is confined to an optional build lane.
        - Consequence: Every operation dispatches on the tag; the GPL lane stays out of the default wheel and the `igraph`-only algorithms move behind it.
        - Confirmation: The carrier type-checks under strict mode and the default build excludes the GPL tag.
        - Premises: [FACT] `<unit>/planning/graph.md:55` carries the string union.
    ```
- Reason: A record binds downstream by asserting one resolution as law; a hedged ruling binds nothing and forces the authoring pass to re-decide what the interview already paid for.
- Reframe: Compress the ruling to one owning sentence in the indicative, move the weighing into `Drivers` and `Options`, and record the losing branch under `Rejected` with its argument.

## [02]-[REJECTION_WITHOUT_REOPEN]

A rejected option records the argument that lost it but not the condition that revives it, so a future session cannot tell a closed door from a permanent wall.

- Detection: A `Rejected` field naming the loser and its defeat with no `reopens when` clause, stranding the reader who hits the exact condition that revives it.
- Rejected:
    ```markdown rejected
    - [07]-[ACCEPTED]: Graph carrier ownership
        - Ruling: `GraphCarrier` is one tagged-union owner over three backends.
        - Rejected: per-backend owner — proliferates one concept across three surfaces against the collapse law.
    ```
- Accepted:
    ```markdown accepted
    - [07]-[ACCEPTED]: Graph carrier ownership
        - Ruling: `GraphCarrier` is one tagged-union owner over three backends.
        - Rejected: per-backend owner — proliferates one concept across three surfaces against the collapse law; reopens when a backend's algorithm set diverges so far that a shared traversal contract costs more than three owners.
    ```
- Reason: The reopen condition is the record's forward value — it tells a future maintainer whether the ground has shifted; without it the rejection reads as dogma and gets re-argued from zero.
- Reframe: Append `reopens when <condition>` to every rejection that stays useful, naming the observable that revives the losing option.

## [03]-[UNMARKED_ASSUMPTION]

An assumption enters a record dressed as a fact, stripping the invalidating condition a future session needs to know when the ruling expired.

- Detection: A `Premises` mark reading `[FACT]` on a claim no anchor supports — a future consumer's behavior, an unbuilt seam — with no condition that falsifies it.
- Rejected:
    ```markdown rejected
    - [03]-[ACCEPTED]: Impact search stays deferred
        - Premises: [FACT] a downstream consumer drives the impact search sweep.
    ```
- Accepted:
    ```markdown accepted
    - [03]-[ACCEPTED]: Impact search stays deferred
        - Premises: [ASSUMPTION] a downstream consumer drives the impact search sweep — invalidated when the impact owner must serve search standalone, which pulls the deferred sweep into current scope.
    ```
- Reason: Marks are load-bearing — `[FACT]` carries its anchor and `[ASSUMPTION]` carries its invalidating condition; mislabeling an unverified premise as `[FACT]` hides the tripwire that tells the next session the ground moved.
- Reframe: Mark every premise `[FACT]`, `[ASSUMPTION]`, or `[INFERENCE]`; give each assumption the observable that falsifies it, and convert any premise that cannot be anchored to an open question.

## [04]-[THREADLESS_RULING]

A decision record seals a Ruling no question thread forced — the `Context` names no observed pressure and the `Premises` carries no anchored fact — so the record reads as the interviewer's preference wearing a decision's leader.

- Detection: A `Ruling` whose `Context` states a generic need rather than an observed force and whose `Premises` cites no path — the seal traces to nothing, so a future session cannot tell what pressure produced the decision or whether it still holds.
- Rejected:
    ```markdown rejected
    - [07]-[ACCEPTED]: Graph carrier ownership
        - Context: The graph layer needs a clear ownership model.
        - Ruling: `GraphCarrier` is one tagged-union owner over three backends.
        - Premises: [INFERENCE] a single owner is the cleaner design.
    ```
- Accepted:
    ```markdown accepted
    - [07]-[ACCEPTED]: Graph carrier ownership
        - Context: `<unit>/planning/graph.md:55` types the carrier as a string union no type-checker resolves and the third arm is GPL; strict typing is house law, so the union cannot stand.
        - Drivers: Strict-typing law; GPL isolation; single-owner collapse.
        - Options: single tagged owner | per-backend owner
        - Ruling: `GraphCarrier` is one tagged-union owner; each backend is a resolvable tag and the GPL backend is confined to an optional build lane.
        - Consequence: Every operation dispatches on the tag; the GPL lane stays out of the default wheel.
        - Confirmation: The carrier type-checks under strict mode and the default build excludes the GPL tag.
        - Premises: [FACT] `<unit>/planning/graph.md:55` carries the string union and the GPL third arm.
    ```
- Reason: A ruling earns its seal from the thread that forced it — the observed force in `Context` and the anchored fact in `Premises` are the record's trace back to the pressure it resolves; a ruling with neither is a preference the next session re-litigates, because nothing on the record shows the ground that produced it.
- Reframe: Trace every ruling to its forcing thread — put the observed force and its anchor in `Context`, mark the load-bearing premise `[FACT]` with its path — and where the thread names no force, the record is a preference, not a decision, and drops until a thread produces it.

## [05]-[SINGLE_TIER_COSTUMES]

A direction set dresses one idea in three costumes — three variations at the same tier — instead of spanning the scope-time spectrum the fan exists to open.

- Detection: Every direction carries the same tier token and one thesis, differing only in a knob; the set offers no real fork between a patch, a structural fix, and a rebuild.
- Rejected:
    ```markdown rejected
    - [01]-[STRUCTURAL]: Tagged union carrier
    - [02]-[STRUCTURAL]: Tagged union with a resolver cache
    - [03]-[STRUCTURAL]: Tagged union with lazy backend load
    ```
- Accepted:
    ```markdown accepted
    - [01]-[PATCH]: Type the union in place
        - Thesis: Replace the string union with a tagged union at its one call site; smallest change that restores type-checking.
        - Cost: One page; leaves the GPL lane in the default build.
        - Kills: Nothing structural — a later split stays open.
        - Reversibility: Full.
        - Evidence: `<unit>/planning/graph.md:55` is the sole carrier site.
        - Confidence: high
    - [02]-[STRUCTURAL]: Split the GPL backend out
        - Thesis: Confine the GPL backend to an optional lane; the core carries only permissive backends.
        - Cost: A build-lane split and a re-home of the `igraph`-only algorithms.
        - Kills: A single default wheel carrying every algorithm.
        - Reversibility: Partial — the lane split is sticky.
        - Evidence: The GPL license on the carrier's third arm.
        - Confidence: medium
    - [03]-[REBUILD]: Backend-agnostic graph service
        - Thesis: Own graph compute as a service admitting backends by capability, not by type.
        - Cost: A new owner and a capability registry.
        - Kills: Direct backend access from consumers.
        - Reversibility: Low.
        - Evidence: No current consumer needs runtime backend selection.
        - Confidence: low
    ```
- Reason: A set of variations on one thesis hides the real decision — how far to reach — behind a knob nobody needs; a true set spans tiers so the user rules on scope, not on tuning.
- Reframe: Generate directions across at least two tier tokens with materially different theses — the single-token set is the mechanical tell, the identical-thesis set the tell only the cold read catches — attack each with the evidence inconsistent with it, and record thesis, cost, kills, reversibility, and confidence per direction.

## [06]-[DUPLICATE_MINTED_ID]

A section mints the same `[<id>]` on two leaders — a collision that leaves the id resolving to neither entry — where the legal form mints each id once in its owning section and cites it by the same token from a scoring or ruling section.

- Detection: Two leaders in one section carry an identical `[<id>]` token, so a fold-back, a wargame row, or a cross-artifact reference to that id addresses nothing; distinct from a later section repeating a minted id, which is reference, not a second mint.
- Rejected:
    ```markdown rejected
    ## [02]-[DIRECTIONS]

    - [01]-[PATCH]: Type the union in place
    - [01]-[STRUCTURAL]: Split the GPL backend out
    ```
- Accepted:

    ```markdown accepted
    ## [02]-[DIRECTIONS]

    - [01]-[PATCH]: Type the union in place
    - [02]-[STRUCTURAL]: Split the GPL backend out

    ## [03]-[WARGAME]

    - Criteria: [COVERAGE]:0.6 | [ISOLATION]:0.4
    - [01]: 3 4 = 3.4
    - [02]: 5 2 = 3.8

    ## [04]-[RULING]

    - Leading: [02] wins on algorithm coverage against a thesis that survived disconfirmation.
    ```

- Reason: An id is the record's addressable handle — minted once, it lets a later section, a fold-back, or a cross-artifact reference point at exactly one entry; a second mint of the same id inside one section resolves to neither entry, while the same token in a scoring or ruling section is a legal reference.
- Reframe: Mint each id once in its owning section and cite it by the same token from later sections; when two entries collide on an id, renumber the second at its mint, never at a reference.

## [07]-[MISCOVERED_WARGAME]

A wargame section scores a set that drifted from its directions — a phantom row scoring a direction that never entered, an entered direction never scored — so the comparison decides on a roster the fan did not produce.

- Detection: The wargame's score-row ids and the DIRECTIONS entry ids diverge in either direction; the sensitivity line reasons over a row with no thesis behind it.
- Rejected:

    ```markdown rejected
    ## [02]-[DIRECTIONS]

    - [01]-[PATCH]: Type the union in place
    - [02]-[STRUCTURAL]: Split the GPL backend out

    ## [03]-[WARGAME]

    - Criteria: [TYPE_SAFETY]:3 | [LICENSE]:2
    - [01]: 3 2 = 13
    - [03]: 2 3 = 12
    ```

- Accepted:

    ```markdown accepted
    ## [02]-[DIRECTIONS]

    - [01]-[PATCH]: Type the union in place
    - [02]-[STRUCTURAL]: Split the GPL backend out

    ## [03]-[WARGAME]

    - Criteria: [TYPE_SAFETY]:3 | [LICENSE]:2
    - [01]: 3 2 = 13
    - [02]: 2 3 = 12
    ```

- Reason: The wargame is the direction set's own scoring, so its roster is the DIRECTIONS roster by construction — a phantom row smuggles in an unexamined option, and an unscored direction exits the comparison silently; the cold-read seal rejects both drift directions.
- Reframe: Score exactly the entered directions, one row per direction id in entry order, and let the sensitivity line reason only over rows the set carries.

## [08]-[DATED_HORIZON]

A roadmap horizon carries a dated task list — a plan leaking upward — where the schema demands an outcome and the condition that promotes it.

- Detection: A horizon entry whose `Bet` or body sequences dated work — week one, then week two — instead of naming a change in behavior and how attainment is observed.
- Rejected:
    ```markdown rejected
    - [01]: Ship the graph carrier
        - Bet: Week 1 write the tagged union; week 2 wire the resolver; week 3 add the tests.
    ```
- Accepted:

    ```markdown accepted
    ## [01]-[NOW]

    - [01]: Graph carrier type-checks under strict mode
        - Why: The string union blocks every downstream graph consumer from strict typing.
        - Bet: A tagged-union owner with a per-backend resolver.
        - Measure: The carrier passes strict type-check and consumers drop their `Any` casts.
        - Confidence: The carrier has one call site.

    ## [02]-[NEXT]

    - [02]: The GPL backend leaves the default wheel
        - Why: The default build ships a GPL surface it does not need.
        - Bet: An optional build lane for the GPL backend.
        - Measure: The default wheel excludes the GPL tag.
        - Promote: A consumer names a GPL-only algorithm it depends on, or the license audit flags the default wheel.
    ```

- Reason: Horizons are confidence bands, not schedules; a dated task list belongs to the plan that its execution consumes, and lodging it in the roadmap freezes a sequence the roadmap has no authority to hold.
- Reframe: State each entry as an outcome with its measure, move dated mechanics down to the plan, and give every `[NEXT]` entry a `Promote` condition that carries it into `[NOW]`.

## [09]-[ANCHORLESS_FINDING]

A blindspot finding records a feeling with no anchor, so a reader cannot verify it, size its blast radius, or fold it back into the owning task.

- Detection: A finding whose `Anchor` is a vibe — "feels under-typed", "seems fragile" — with no path, no observed fact, and a consequence stated as a guess.
- Rejected:
    ```markdown rejected
    - [01]-[APPROACH]-[OPEN]: The graph carrier feels under-typed
        - Anchor: general impression from reading the page.
        - Consequence: might cause problems later.
    ```
- Accepted:
    ```markdown accepted
    - [01]-[CAPABILITY_WEAKNESS]-[OPEN]: Graph carrier types as a string union
        - Anchor: `<unit>/planning/graph.md:55` — `AnyGraph = "RxGraph | NxGraph | igraph.Graph"`, a string no type-checker resolves.
        - Consequence: Every consumer casts through `Any`, strict mode misses a wrong-backend call, and the GPL backend rides the default surface unmarked; the blast reaches every graph consumer.
        - Fold-back: Retype `GraphCarrier` as a tagged union, confine the GPL tag to an optional lane, and drop the consumer `Any` casts.
        - Route: The graph carrier owner.
    ```
- Reason: A finding earns entry by surviving on-disk verification — the anchor is the evidence and the blast radius is the rank; a vibe carries no order, no proof, and no landing surface.
- Reframe: Re-open the candidate on disk, record the path and the observed fact as `Anchor`, size the blast in `Consequence`, and write the `Fold-back` as the copyable prompt that lands the fix.

## [10]-[ORPHANED_FINDING]

A blindspot finding proves its anchor and sizes its blast but carries no `Fold-back` — the copyable prompt that lands the fix — so the finding names a problem no task can pick up and the blindspot survives the pass that found it.

- Detection: A finding with a verified `Anchor` and a sized `Consequence` and a named `Route` but no `Fold-back` — a diagnosis with no prescription, leaving the owner a problem restated instead of a change to make.
- Rejected:
    ```markdown rejected
    - [01]-[CAPABILITY_WEAKNESS]-[OPEN]: Graph carrier types as a string union
        - Anchor: `<unit>/planning/graph.md:55` — `AnyGraph = "RxGraph | NxGraph | igraph.Graph"`, a string no type-checker resolves.
        - Consequence: Every consumer casts through `Any`; the blast reaches every graph consumer.
        - Route: The graph carrier owner.
    ```
- Accepted:
    ```markdown accepted
    - [01]-[CAPABILITY_WEAKNESS]-[OPEN]: Graph carrier types as a string union
        - Anchor: `<unit>/planning/graph.md:55` — `AnyGraph = "RxGraph | NxGraph | igraph.Graph"`, a string no type-checker resolves.
        - Consequence: Every consumer casts through `Any`; the blast reaches every graph consumer.
        - Fold-back: Retype `GraphCarrier` as a tagged union over the three backends, confine the GPL tag to an optional lane, and drop the consumer `Any` casts.
        - Route: The graph carrier owner.
    ```
- Reason: A ledger exists to convert findings into work — the `Fold-back` is the carrier, the exact prompt the `Route` owner picks up verbatim; a finding with anchor and blast but no fold-back strands the fix, and the next pass re-discovers the same weakness from zero.
- Reframe: Write the `Fold-back` as the change to make in the `Route` owner, not the problem restated; a finding that cannot yield one is not yet understood well enough to record, and drops back to a corpus check.

## [11]-[UNCHECKED_GAPS]

A capability entry asserts an empty `Gaps` field by assumption, claiming the surface is fully exploited without checking the admitted capability against the owner.

- Detection: A `Gaps` of `none` on a capability whose owner demonstrably leaves admitted library surface unused, and a maturity marker inflated past the built reality.
- Rejected:
    ```markdown rejected
    - [01]-[BUILT]: Impact assessment over element sets
        - Owner: The impact domain owner.
        - Edges: depends-on the element graph; consumed-by the assessment report.
        - Importance: Serves the environmental-scoring direction.
        - Gaps: none.
    ```
- Accepted:
    ```markdown accepted
    - [01]-[GENESIS]: Impact assessment over element sets
        - Owner: The impact domain owner.
        - Edges: depends-on the element graph; consumed-by the assessment report.
        - Importance: Serves the environmental-scoring direction.
        - Gaps: The admitted impact library owns an EC3 search stream and wide `MultiLCA` sweeps the owner gates behind an unnamed consumer; both are unexploited capability, so the surface is a thin slice, not a full owner.
    ```
- Reason: `Gaps` is the load-bearing field for elicitation — an empty gaps field asserts full exploitation, and that assertion gets checked against the admitted surface, never assumed; the same check corrects the maturity marker the empty field inflated.
- Reframe: Sample the owner against the full attribute and capability space of its admitted dependencies, record every unexploited member as a gap, and set the maturity marker to the built reality the gap check reveals.

## [12]-[DRIFTED_PROJECTION]

A projection fence beside an instance's relation rows asserts an edge no row mints, so the diagram rules a relation the record never sealed and the reader trusts the drawing over the truth it claims to project.

- Detection: The instance's `Edges` or `Depends` rows and the mermaid fence beside them diverge in either direction — a fence edge with no backing row, or a carried row the fence silently drops while presenting itself as the set.
- Rejected:
    ````markdown rejected
    - [01]-[BUILT]: Content-keyed artifact lookup
        - Owner: The artifact index owner.
        - Edges: depends-on the identity kernel; consumed-by the render cache.
    - [02]-[BUILT]: Deterministic render caching
        - Owner: The render cache owner.
        - Edges: depends-on the artifact index.

    ```mermaid
    ---
    config:
      layout: elk
      look: neo
      theme: base
      flowchart:
        padding: 16
      themeCSS: ".nodeLabel{font-size:14px;font-weight:500}.edgeLabel{font-size:12.5px;font-weight:500}.edgePaths path{stroke-width:1.5px}"
      themeVariables:
        darkMode: true
        background: "#282A36"
        primaryColor: "#44475A"
        primaryTextColor: "#F8F8F2"
        primaryBorderColor: "#BD93F9"
        lineColor: "#FF79C6"
        textColor: "#F8F8F2"
        edgeLabelBackground: "#44475A"
        fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    ---
    flowchart LR
        accTitle: Capability edge projection
        accDescr: The artifact index depends on the identity kernel and is consumed by the render cache and the deploy root.
        KERNEL[identity kernel] -->|"depends-on"| INDEX[artifact index]
        INDEX -->|"consumed-by"| CACHE[render cache]
        INDEX -->|"consumed-by"| DEPLOY[deploy root]
        classDef primary fill:#44475A,stroke:#BD93F9,color:#F8F8F2
        classDef external fill:#8BE9FD,stroke:#8BE9FD,color:#282A36
        classDef annotation fill:#21222C,stroke:#6272A4,color:#F8F8F2
        class INDEX primary
        class KERNEL external
        class CACHE,DEPLOY annotation
    ```
    ````
- Accepted:
    ````markdown accepted
    - [01]-[BUILT]: Content-keyed artifact lookup
        - Owner: The artifact index owner.
        - Edges: depends-on the identity kernel; consumed-by the render cache and the deploy root.
    - [02]-[BUILT]: Deterministic render caching
        - Owner: The render cache owner.
        - Edges: depends-on the artifact index.

    ```mermaid
    ---
    config:
      layout: elk
      look: neo
      theme: base
      flowchart:
        padding: 16
      themeCSS: ".nodeLabel{font-size:14px;font-weight:500}.edgeLabel{font-size:12.5px;font-weight:500}.edgePaths path{stroke-width:1.5px}"
      themeVariables:
        darkMode: true
        background: "#282A36"
        primaryColor: "#44475A"
        primaryTextColor: "#F8F8F2"
        primaryBorderColor: "#BD93F9"
        lineColor: "#FF79C6"
        textColor: "#F8F8F2"
        edgeLabelBackground: "#44475A"
        fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"
    ---
    flowchart LR
        accTitle: Capability edge projection
        accDescr: The artifact index depends on the identity kernel and is consumed by the render cache and the deploy root.
        KERNEL[identity kernel] -->|"depends-on"| INDEX[artifact index]
        INDEX -->|"consumed-by"| CACHE[render cache]
        INDEX -->|"consumed-by"| DEPLOY[deploy root]
        classDef primary fill:#44475A,stroke:#BD93F9,color:#F8F8F2
        classDef external fill:#8BE9FD,stroke:#8BE9FD,color:#282A36
        classDef annotation fill:#21222C,stroke:#6272A4,color:#F8F8F2
        class INDEX primary
        class KERNEL external
        class CACHE,DEPLOY annotation
    ```
    ````

- Reason: The rows are the truth the fence projects — a fence edge without its row is an unruled relation smuggled in as settled fact, and once the drawing and the record disagree every future reader must guess which one lies; the seal's cold read rejects the divergence in either direction.
- Reframe: Derive the fence from the sealed rows, re-derive it on every row edit, and repair a fence-row diff at whichever end is wrong — mint the missing row when the relation is real, delete the fence edge when it is not.
