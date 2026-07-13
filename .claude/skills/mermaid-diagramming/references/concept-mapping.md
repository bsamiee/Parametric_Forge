# [CONCEPT_MAPPING]

A concept arrives as code, prose, a plan, or an argument — never as a diagram type. The structural shape inside the material selects the archetype, and each shape betrays itself through signals readable before any node exists. Recognition classifies that shape; question wording, staged growth, and per-type mark law bind downstream.

## [01]-[SHAPE_CATALOG]

Read the material for the shape, not the topic. Every row names the signals that select it and the archetype that owns it; the archetype's template carries the construction law.

| [INDEX] | [SHAPE]             | [SIGNALS_IN_THE_MATERIAL]                       | [ROUTE]                                                         |
| :-----: | :------------------ | :---------------------------------------------- | :-------------------------------------------------------------- |
|  [01]   | mode machine        | _in_ a state; "once X, never back"              | lifecycle                                                       |
|  [02]   | dispatch topology   | one entry point, a discriminant, many arms      | logic-flow                                                      |
|  [03]   | ownership walk      | "first, then, finally" across owners            | spine                                                           |
|  [04]   | dependency lattice  | "X needs Y"; imports; "never depend upward"     | strata                                                          |
|  [05]   | boundary seam       | two packages naming each other's types          | seam-graph                                                      |
|  [06]   | conversation        | parties taking turns; request/response pairs    | wire-sequence                                                   |
|  [07]   | identity web        | "each X has many Y"; uniqueness claims          | schema                                                          |
|  [08]   | command causality   | "when X happens, Y fires"; handlers emit        | event-flow                                                      |
|  [09]   | chronology          | dated occurrences, no causal claim              | history for repositories, `timeline` otherwise                  |
|  [10]   | committed future    | dated work with "after" deps; milestones        | schedule                                                        |
|  [11]   | queue snapshot      | named stages now; ticket/owner vocabulary       | board                                                           |
|  [12]   | zoned deployment    | units in zones over ports and protocols         | topology                                                        |
|  [13]   | system neighborhood | one system and all that talks to it             | landscape                                                       |
|  [14]   | capability profile  | one axis scored across two subjects             | profile                                                         |
|  [15]   | weighted whole      | one measure/unit across parts of a whole        | decomposition                                                   |
|  [16]   | strict taxonomy     | is-a/part-of under one root, no cross-links     | `mindmap`; a needed cross-link makes it a `flowchart`           |
|  [17]   | diagnosis fan       | many conditions converging on one effect        | `ishikawa-beta`                                                 |
|  [18]   | position judgment   | items placed by two independent gradings        | `quadrantChart`; evolution and visibility select `wardley-beta` |
|  [19]   | domain sort         | practices sorted by cause-effect knowability    | `cynefin-beta`                                                  |
|  [20]   | admitted language   | strings/fields/bit-ranges a contract admits     | `railroad-*-beta` for grammars, `packet` for wire formats       |
|  [21]   | laned procedure     | owning actor is the point, handoffs the cost    | `swimlane-beta`                                                 |
|  [22]   | phase sentiment     | one actor path scored by satisfaction per phase | `journey`                                                       |

- mode machine: status or phase vocabulary; an enum field written from many sites under guards
- dispatch topology: match or switch expressions; policy tables; routing rules; "depending on"
- ownership walk: boot narratives; request paths; a composition root
- dependency lattice: layer talk; cycle complaints
- boundary seam: a declared contract ledger; "crosses the boundary"
- conversation: timeout, retry, and ack vocabulary
- identity web: nouns with identifiers; ownership claims over stored facts
- command causality: projections consuming the emitted events
- domain sort: claimed movement between domains

Named archetype routes resolve through the catalog table in the root; bare declarations route through the methodology type table. Two shapes present at once is two diagrams sharing one name vocabulary, never one canvas carrying both.

## [02]-[READING_SIGNALS]

The shape lives in the material's structure, not its subject line — a document titled "architecture" routinely carries a mode machine, and a function named `process` routinely carries a dispatch. The reading discipline classifies before it draws:

- In code: a field with a bounded vocabulary written from several sites is a mode machine regardless of its name; a table of rows consulted by one caller is a dispatch; manifest references are a dependency lattice; paired send and receive calls are a conversation.
- In prose: temporal connectives across owners signal a walk; conditional connectives fanning from one subject signal a dispatch; possessive claims with multiplicity signal an identity web; "leads to" chains signal command causality, never a chronology.
- In an argument: premises converging on a conclusion are a diagnosis fan when the claim is causal, a strict taxonomy when the claim is classification, and a position judgment when two independent gradings do the work.
- In a plan: dated commitments with dependencies are a committed future; undated stage membership is a queue snapshot; the two shapes in one document are two diagrams.

```text rejected
The document lists steps, so it becomes a flowchart of the steps in order.
```

```text accepted
The steps carry three owners and four handoffs between them; ownership is the payload, so the shape is a laned procedure and the fence is swimlane-beta with the steps homed in owner lanes.
| [22] | phase sentiment | one actor path scored by satisfaction per phase | `journey` |
```

The naive reading maps surface order onto arrows; the shape reading asks which relation carries the reader's decision — order, ownership, dependency, causality, or identity — and routes on that relation.

## [03]-[MISFIT_SHAPES]

Some concepts carry no inspectable relation, and a fence forced onto them decorates instead of asserting:
- A scalar comparison across subjects is a table; position on a page adds nothing to two numbers.
- An unordered roster is a list; drawing edges between peers invents relations the material never claimed.
- A single relation across fewer than three parts is a clause; the root's mark threshold owns this floor.
- A quantity distribution, trend, or correlation is a chart, owned by the dataviz skill — the quantitative mermaid rows hold only while the artifact must stay a fence.
- A narrative whose value is its wording — a decision record, a contract clause — stays prose; a diagram of it launders emphasis as structure.

## [04]-[COMPOSITE_SUBJECTS]

A real subject usually carries several shapes at once: a job queue is a mode machine (one job's lifecycle), a conversation (the worker protocol), and a queue snapshot (the backlog now). The partition rule: one diagram per shape, the dominant shape drawn first — dominance belongs to the shape whose relation the reader's decision traverses — and every diagram in the set sharing the exact element names so views resolve against each other. The multi-view composition law, the shared-vocabulary rule, and the scenario cross-check are the methodology reference's property; recognition only decides how many shapes exist and which comes first.
