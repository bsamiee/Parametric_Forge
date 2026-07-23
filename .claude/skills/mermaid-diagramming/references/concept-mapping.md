# [CONCEPT_MAPPING]

A concept arrives as code, prose, a plan, or an argument — never as a diagram type. Structural shape inside the material selects the archetype, and each shape betrays itself through signals readable before any node exists; recognition decides only how many shapes exist and which comes first.

## [01]-[SHAPE_CATALOG]

Co-firing rule binds before any row: two or more rows firing on one subject is the composite signal — route to [04] partition first, because a single-row read of a co-firing subject is the root misroute. Read the material for the shape, not the topic; every row names the signals that select it, and the archetype's template carries the construction law.

| [INDEX] | [SHAPE]             | [SIGNALS_IN_THE_MATERIAL]                            | [ROUTE]                                                   |
| :-----: | :------------------ | :--------------------------------------------------- | :-------------------------------------------------------- |
|  [01]   | mode machine        | a bounded status vocabulary with terminal absorption | lifecycle                                                 |
|  [02]   | dispatch topology   | one entry point, a discriminant, many arms           | logic-flow                                                |
|  [03]   | ownership walk      | "first, then, finally" across owners                 | spine                                                     |
|  [04]   | dependency lattice  | "X needs Y"; imports; "never depend upward"          | strata                                                    |
|  [05]   | boundary seam       | two packages naming each other's types               | seam-graph                                                |
|  [06]   | conversation        | retry/ack over a live wire; request/response turns   | wire-sequence                                             |
|  [07]   | identity web        | "each X has many Y"; uniqueness claims               | schema                                                    |
|  [08]   | command causality   | code-level emit/handle/project vocabulary            | event-flow                                                |
|  [09]   | chronology          | dated occurrences, no causal claim                   | history when branches diverge and merge, else `timeline`  |
|  [10]   | committed future    | dated work with "after" deps; milestones             | schedule                                                  |
|  [11]   | queue snapshot      | named stages now; ticket/owner vocabulary            | board                                                     |
|  [12]   | zoned deployment    | units in zones over ports and protocols              | topology                                                  |
|  [13]   | system neighborhood | one system and all that talks to it                  | landscape                                                 |
|  [14]   | capability profile  | several shared axes scored across two subjects       | profile                                                   |
|  [15]   | weighted whole      | one measure/unit across parts of a whole             | decomposition                                             |
|  [16]   | strict taxonomy     | is-a/part-of under one root, no cross-links          | `mindmap`; a needed cross-link makes it a `flowchart`     |
|  [17]   | diagnosis fan       | many conditions converging on one effect             | `ishikawa-beta`                                           |
|  [18]   | position judgment   | items placed by two independent continuous gradings  | `quadrantChart`; evolution/visibility -> `wardley-beta`   |
|  [19]   | domain sort         | practices sorted by cause-effect knowability         | `cynefin-beta`                                            |
|  [20]   | admitted language   | strings/fields/bit-ranges a contract admits          | `railroad-*-beta` for grammars, `packet` for wire formats |
|  [21]   | laned procedure     | owning actor is the point, handoffs the cost         | `swimlane-beta`                                           |
|  [22]   | phase sentiment     | one actor path scored by satisfaction per phase      | `journey`                                                 |
|  [23]   | fixed grid          | cell position and span carry the claim; memory maps  | `block-beta`                                              |
|  [24]   | compile-time web    | inheritance, composition, interface claims in source | `classDiagram`                                            |
|  [25]   | on-disk containment | file and directory listings, trailing-slash truth    | `treeView-beta`                                           |
|  [26]   | conserved flow      | quantities splitting across stages, totals conserved | `sankey`                                                  |
|  [27]   | measured overlap    | membership counts shared between named sets          | `venn-beta`                                               |
|  [28]   | demanded trace      | requirements satisfied or verified by artifacts      | `requirementDiagram`                                      |

- mode machine: an enum field written from many sites under guards; unbounded monotone accumulation — grow-only sets, counters, append-only logs — never qualifies, and routes to dataflow or event shapes instead
- dispatch topology: match or switch expressions; policy tables — a retry policy table is a dispatch, and retry exhaustion into a dead-letter is a mode machine; routing rules; "depending on"
- ownership walk: boot narratives; request paths; a composition root — "pipeline" is shape-ambiguous, so read whether order, dependency, or a cache/skip decision carries the payload, and treat conditional skips as dispatch arms
- dependency lattice: layer talk; cycle complaints — member-level seams inside a lattice co-fire row [05], strata rungs dominant and the seam view second
- boundary seam: a declared contract ledger; "crosses the boundary"
- identity web: nouns with identifiers; ownership claims over stored facts
- command causality: projections consuming emitted events — a dated incident narrative whose entries assert cause is a causal chronology, drawn as a `timeline` with the causal claims annotated or a `swimlane-beta` by responder, never event-flow
- domain sort: claimed movement between domains

Named archetype routes resolve through the catalog table in the root; bare declarations route through the methodology type table.

## [02]-[READING_SIGNALS]

Shape lives in the material's structure, not its subject line — a document titled "architecture" routinely carries a mode machine, and a function named `process` routinely carries a dispatch. Medium sets the reading discipline, because one shape wears different clothes per medium:

- In code: the shape signals are the catalog's, read against declarations rather than names — the field, the table, the manifest, the paired calls.
- In prose: temporal connectives across owners signal a walk; conditional connectives fanning from one subject signal a dispatch; possessive claims with multiplicity signal an identity web; "leads to" chains signal command causality only when the vocabulary is code-level emit and handle — a dated narrative asserting cause is the causal chronology the catalog routes to timeline.
- In an argument: premises converging on a conclusion are a diagnosis fan when the claim is causal, a strict taxonomy when the claim is classification, and a position judgment when two independent gradings do the work.
- In a plan: dated commitments with dependencies are a committed future; undated stage membership is a queue snapshot; the two shapes in one document are two diagrams.

```text rejected
The document lists steps, so it becomes a flowchart of the steps in order.
```

```text accepted
The steps carry three owners and four handoffs between them; ownership is the payload, so the shape is a laned procedure and the fence is swimlane-beta with the steps homed in owner lanes.
```

Naive reading maps surface order onto arrows; the shape reading asks which relation the material most describes — order, ownership, dependency, causality, or identity — and routes on that relation.

## [03]-[MISFIT_SHAPES]

Some concepts carry no inspectable relation, and a fence forced onto them decorates instead of asserting:
- A scalar comparison across subjects is a table; position on a page adds nothing to two numbers, and a single-axis two-subject compare is this misfit, never a degenerate one-spoke profile.
- A discrete cross-product matrix — role by resource, feature by tier — is a table, or `block-beta` when placement itself is the meaning; the decision logic it feeds is a separate dispatch shape.
- An unordered roster is a list; drawing edges between peers invents relations the material never claimed.
- A single relation across fewer than three parts is a clause; the root's mark threshold owns this floor.
- A quantity distribution, trend, or correlation is a chart, not a diagram — the quantitative mermaid rows hold only while the artifact must stay a fence.
- A narrative whose value is its wording — a decision record, a contract clause — stays prose; a diagram of it launders emphasis as structure.

## [04]-[COMPOSITE_SUBJECTS]

A real subject carries several shapes: a job queue is a mode machine (one job's lifecycle), a conversation (the worker protocol), and a queue snapshot (the backlog now); a member-resolved dependency lattice co-fires strata (dominant) and seam-graph (second view). Partition rule: one diagram per shape, dominant first — dominance belongs to the relation the material most describes, or the relation a downstream task consumes — every diagram sharing exact element names so views resolve against each other. Multi-view composition and the scenario cross-check are the methodology reference's property.
