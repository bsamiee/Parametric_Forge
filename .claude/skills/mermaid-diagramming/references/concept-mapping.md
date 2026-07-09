# [CONCEPT_MAPPING]

A concept arrives as code, prose, a plan, or an argument — never as a diagram type. This reference owns the recognition step between raw material and the written question: the structural shape inside the material selects the archetype, and each shape betrays itself through signals readable before any node exists. Question wording, staged growth, and per-type mark law bind downstream in the methodology and construction references; recognition binds here.

## [01]-[SHAPE_CATALOG]

Read the material for the shape, not the topic. Every row names the signals that select it and the archetype that owns it; the archetype's template carries the construction law.

| [INDEX] | [SHAPE]             | [SIGNALS_IN_THE_MATERIAL]                                                                                                                         | [ROUTE]                                                         |
| :-----: | :------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------- |
|  [01]   | mode machine        | an entity described as being *in* something; status or phase vocabulary; "once X, never back"; an enum field written from many sites under guards | lifecycle                                                       |
|  [02]   | dispatch topology   | one entry point, a discriminant, many arms; match or switch expressions; policy tables; routing rules; "depending on"                             | logic-flow                                                      |
|  [03]   | ownership walk      | "first, then, finally" across distinct owners; boot narratives; request paths; a composition root                                                 | spine                                                           |
|  [04]   | dependency lattice  | "X needs Y"; import lists; layer talk; "must never depend upward"; cycle complaints                                                               | strata                                                          |
|  [05]   | boundary seam       | two packages naming each other's types; a declared contract ledger; "crosses the boundary"                                                        | seam-graph                                                      |
|  [06]   | conversation        | two or more parties taking turns; request and response pairs; timeout, retry, and ack vocabulary                                                  | wire-sequence                                                   |
|  [07]   | identity web        | nouns with identifiers; "each X has many Y"; uniqueness and ownership claims over stored facts                                                    | schema                                                          |
|  [08]   | command causality   | "when X happens, Y fires"; handlers emitting events; projections consuming them                                                                   | event-flow                                                      |
|  [09]   | chronology          | dated occurrences across periods with no causal claim                                                                                             | history for repositories, `timeline` otherwise                  |
|  [10]   | committed future    | owned work with dates and "after" dependencies; milestone talk                                                                                    | schedule                                                        |
|  [11]   | queue snapshot      | work sitting in named stages right now; ticket and owner vocabulary                                                                               | board                                                           |
|  [12]   | zoned deployment    | units running in zones, reaching each other over ports and protocols                                                                              | topology                                                        |
|  [13]   | system neighborhood | one system and everything that talks to it, at one audience's altitude                                                                            | landscape                                                       |
|  [14]   | capability profile  | one axis vocabulary scored across two subjects                                                                                                    | profile                                                         |
|  [15]   | weighted whole      | one measure in one unit distributed across parts of a whole                                                                                       | decomposition                                                   |
|  [16]   | strict taxonomy     | is-a or part-of decomposition under one root, no cross-links                                                                                      | `mindmap`; a needed cross-link makes it a `flowchart`           |
|  [17]   | diagnosis fan       | many suspected conditions converging on one named effect                                                                                          | `ishikawa-beta`                                                 |
|  [18]   | position judgment   | items placed by two independent assessments                                                                                                       | `quadrantChart`; evolution and visibility select `wardley-beta` |
|  [19]   | domain sort         | practices classified by how knowable their cause-effect is, with claimed movement                                                                 | `cynefin-beta`                                                  |
|  [20]   | admitted language   | which strings, fields, or bit ranges a contract accepts                                                                                           | `railroad-*-beta` for grammars, `packet` for wire formats       |
|  [21]   | laned procedure     | steps whose owning actor is the point, handoffs the cost                                                                                          | `swimlane-beta`                                                 |

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
