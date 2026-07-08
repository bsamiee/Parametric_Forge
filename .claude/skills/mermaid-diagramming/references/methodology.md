# [METHODOLOGY]

A diagram is the answer to one written question; its node set, edge set, type, and count all derive from that question.

## [01]-[QUESTION_FIRST]

- Removal test: a fence earns its slot only when page meaning changes on its removal; below that threshold prose or a table owns the fact.
- One-question law: the question lands as one sentence before any node exists — an unwritable question means the subject splits into separate diagrams.
- Audience sets abstraction: the reader's decision picks the level, never the available implementation detail.
- Diagrams stay out of lists, scalar facts, decision records, and API contracts that carry no inspectable relation.

## [02]-[INVESTIGATION]

The pre-drawing procedure runs in order before the first shape.

1. Inventory candidate entities, relations, and attributes on separate lists, keeping attributes off the node roster.
2. Classify every relation into one semantic family — ownership, dependency, dataflow, invocation, sequence, containment, state-transition.
3. Select one family as the payload and discard every entity that neither participates in it nor anchors a boundary.
4. Trace one representative scenario, because runtime behavior exposes the real seams a file layout hides.
5. Fix a canonical name vocabulary — external actors, internal elements, relation verbs, allowed abbreviations — before the first fence.

Each archetype names the corpus evidence that seeds its inventory; a diagram drawn from memory instead of these traces fabricates its subject.

- [01]-[SPINE]: the boot entrypoint and composition root — walk main from process start to shutdown, listing every owner touched in order and every call that can fault
- [02]-[SEAM-GRAPH]: cross-package imports and the declared seam ledger — every type that crosses the boundary, its direction, and the counterpart's mirror declaration
- [03]-[LOGIC-FLOW]: the dispatch surface — the match, table, or policy rows of the one entry point, its discriminant vocabulary, and where the arms re-merge
- [04]-[LIFECYCLE]: the state field — its bounded vocabulary, every write site as a transition candidate, every guard condition at each write
- [05]-[WIRE-SEQUENCE]: protocol handlers on both sides of the wire — the request and response shapes, the timeout and fault arms, who initiates each step
- [06]-[SCHEMA]: the DDL, migrations, or model declarations — real PK, FK, and unique constraints, never the ORM's intended usage
- [07]-[STRATA]: the manifest dependency edges — declared package references, the permitted direction law, and any recorded violation
- [08]-[SCHEDULE]: the task ledger and its dependency claims — real dates, the `after` chains a plan asserts, and the milestone the chains converge on
- [09]-[BOARD]: the tracker state — queue membership, ticket ids, owners, and priorities as recorded, never as remembered
- [10]-[HISTORY]: `git log --graph` over the range — branch points, merge directions, tags, and the ids of the commits that carried the work
- [11]-[TOPOLOGY]: the deployment manifests — units, zones, and the port or protocol each edge traverses
- [12]-[LANDSCAPE]: the ownership map at one zoom — which systems the boundary owns, which sit outside, and the verb each relation carries
- [13]-[EVENT-FLOW]: the command handlers and event log — which command emits which event, which projection consumes it, in causal order
- [14]-[PROFILE]: the assessment record — the axis vocabulary and the scored evidence per subject, with the scoring basis stated beside the fence
- [15]-[DECOMPOSITION]: the measured inventory — one measure in one unit per leaf, summed bottom-up so parents mean their children

## [03]-[STAGED_GROWTH]

A committed diagram is grown in rounds, never drawn at final size in one pass; naive size — the first seven boxes that come to mind — is the floor the rounds build past.

1. Orientation: reading order carries the payload — `LR` for walks, flows, and time, `TB` for altitude, hierarchy, and dependency descent; left or top holds the entry, and a diagram whose walk runs against its reading order is re-oriented before it grows.
2. Skeleton: the dominant rail alone at one abstraction level — entry, the load-bearing owners, the terminal. Every later mark subordinates to this rail.
3. Interrogation rounds: each round asks one named reader question against the skeleton — where does this fault, what stores the fact, who sits outside the boundary, what selects the arm, what returns — and admits only the marks that answer it. A round that adds no mark closes the growth.
4. Layering round: meaning that earns presence but not a node lands on the secondary vocabulary — edge labels, notes, annotation-classed side nodes on the Comment rail, subgraph membership, dashed traces — so density rises without new primary marks.
5. Split check: growth stops the moment a round's question is a second question — that round becomes a new diagram sharing the same name vocabulary, not a larger canvas.

The node-annotation-omission ladder rules every candidate mark:

- NODE — it owns, receives, transforms, stores, decides, or transitions under the payload relation and carries at least one committed edge.
- EDGE LABEL — it qualifies one relation with its verb, kind, or guard; it has no independent existence off that edge.
- ANNOTATION — a reader decision needs it, but it holds no payload relation: a note, a brace comment, or an `annotation`-classed node on a dashed Comment trace.
- OMISSION — its removal leaves the answer intact; the owning page's prose carries it, and the diagram does not.

A massive subject stays one diagram only while every mark still serves the single question under hierarchy — composites, subgraphs, summarizing nodes; a needed legend, a second edge semantic, or density that aggregation cannot cure is the split, partitioned along the seam the reader already knows: phase, aggregate, package, or gate.

## [04]-[NODE_LAW]

- Every primary node holds the same abstraction level; a product beside a function makes edge semantics unknowable.
- A concept reaches node status only when it owns, receives, transforms, stores, decides, or transitions under the payload relation.
- Technologies, protocols, versions, and statuses demote to labels unless the question asks how those items relate to each other.
- The smallest node set answers the question; when a graph becomes a search task instead of a read, hierarchy, filtering, or a split lands first.
- Names are canonical domain nouns found in source, glossary, or architecture record — never `manager`, `processor`, `handler`, `service`.
- Omission test: a node whose removal leaves the answer intact is deleted.

## [05]-[EDGE_LAW]

- One edge semantic carries the whole diagram.
- Every edge holds a specific verb phrase matching its direction — `publishes events to`, `validates token with`, never `uses`.
- Direction draws only for an asymmetric relation, and a bidirectional edge never dodges the real semantics of two distinct claims.
- Cardinality appears only when multiplicity changes the reader's decision on capacity, ownership, optionality, or fan-out.
- Edge crossings are defects unless the crossing is the subject; the repair is split, reorder, aggregate, or a type change.
- Structural edges never imply time; first, next, retry, and timeout route to a sequence or state diagram.
- No edge skips an abstraction level — the intermediate owner joins the view or the whole view drops one level.

## [06]-[VISUAL_ENCODING]

Every visual channel is spent deliberately; a channel spent twice on one meaning, or once on two meanings, is a defect.

- Shape carries kind, color carries category or status, stroke carries state, edge style carries relation modality, text carries exact semantics — and critical meaning lands twice, text plus one visual form.
- A `subgraph` asserts membership; a color class asserts a distributed category; both together assert two real memberships, never reinforcement. A node enclosed for visual neatness reads as a member — the enclosure is the claim.
- Six categorical classes bound a diagram; past six the category moves to labels, groups, or a split. Every color-coded meaning carries a redundant encoding, so the diagram survives grayscale and color-blind readers.
- Node labels are noun phrases with the discriminating word first; edge labels are verb phrases; direct labels beat legends — a legend is a lookup jump forced on every read.
- Dashed and dotted strokes carry modality — optional, planned, inferred — never primary direction; direction rides the arrowhead.
- Dense many-to-many interiors defeat node-link reading; the repair is a summarizing node, a split, or a table, never a bigger canvas.
- Peers declare contiguously and flows declare in walk order — declaration order is the author's one lever over layout stability wherever the engine offers no stronger one; where it does, the stronger lever is spent: ELK model order and rank edges on flowcharts, `align row|column` plus edge ports on architecture, boundary homing on C4, adjacent-cell linking on block grids.
- A crossing found in the render is repaired at the source — reorder declarations, re-home a member, re-port an edge, or split the figure — never accepted as engine fate; the render is re-proven after the repair.
- A diagram read by an agent keeps its source fence beside the render, names nodes uniquely, and states every relation as an explicit labeled edge — spatial implication is invisible to a machine reader.

## [07]-[TYPE_SELECTION]

The question shape selects the declaration; the full grammar, floor, and trap roster per row is the syntax reference's property.

| [INDEX] | [QUESTION]                                   | [TYPE]                        |
| :-----: | :------------------------------------------- | :---------------------------- |
|  [01]   | what exists and relates                      | `flowchart`                   |
|  [02]   | who exchanges what in order                  | `sequenceDiagram`             |
|  [03]   | which modes and transitions                  | `stateDiagram-v2`             |
|  [04]   | what data, keys, and cardinality             | `erDiagram`                   |
|  [05]   | which types relate at compile time           | `classDiagram`                |
|  [06]   | which owner performs which step              | `swimlane-beta`               |
|  [07]   | which commands yield which events            | `eventmodeling`               |
|  [08]   | system landscape at one zoom                 | `C4`                          |
|  [09]   | which deployable runs where                  | `architecture-beta`           |
|  [10]   | dated committed work                         | `gantt`                       |
|  [11]   | which stage holds which work now             | `kanban`                      |
|  [12]   | how branches diverge and merge               | `gitGraph`                    |
|  [13]   | what occurred across periods                 | `timeline`                    |
|  [14]   | how satisfaction moves across phases         | `journey`                     |
|  [15]   | radial concept decomposition                 | `mindmap`                     |
|  [16]   | weighted whole-to-part decomposition         | `treemap-beta`                |
|  [17]   | filesystem or containment truth              | `treeView-beta`               |
|  [18]   | fixed-grid placement as the meaning          | `block-beta`                  |
|  [19]   | requirement-to-artifact traceability         | `requirementDiagram`          |
|  [20]   | part-to-whole share inside a fence           | `pie`                         |
|  [21]   | two independent judgments as position        | `quadrantChart`               |
|  [22]   | weighted flow through stages                 | `sankey`                      |
|  [23]   | categories against a measure                 | `xychart`                     |
|  [24]   | multivariate profile comparison              | `radar-beta`                  |
|  [25]   | measured set overlap                         | `venn-beta`                   |
|  [26]   | capability position on evolution             | `wardley-beta`                |
|  [27]   | decision-domain sort with movement           | `cynefin-beta`                |
|  [28]   | admitted strings rule by rule                | `railroad-*-beta`             |
|  [29]   | plausible causes of one effect               | `ishikawa-beta`               |
|  [30]   | wire-format bit contract                     | `packet`                      |

The quantitative rows — pie, xychart, sankey, radar — hold only while the artifact must stay a mermaid fence; a standing data visualization routes to the dataviz lane.

[CONTRAST]: classic mismatches, each repaired by payload alignment:

- lifecycle drawn as flowchart -> `stateDiagram-v2`
- call order drawn as graph -> `sequenceDiagram`
- dependency drawn as sequence -> `flowchart`
- ownership lanes drawn as subgraph decoration -> `swimlane-beta`
- a tree with one needed cross-link -> `flowchart`, the subject is a graph
- quantity drawn as node-link -> chart

## [08]-[SOUNDNESS]

Every committed diagram passes a mechanical audit; each finding blocks the fence.

- [MACHINE] — the bundled `validate_mermaid.py` owns the machine roster, blocking on structural defects and warning on legibility pressure; its output is the authority.
- [JUDGMENT] — the reviewer clears these before commit:
  - a cycle in a domain declared acyclic
  - one concept rendered under two names
  - an edge skipping the declared abstraction level
  - mixed edge semantics hidden behind precise labels
  - a legend explaining two taxonomies or two edge semantics
  - a diagram needing narration to supply its own title, scope, node types, or edge meaning

## [09]-[COMPOSITION]

- Zoom levels are separate diagrams for separate audiences, added only while a lower-level question stays unanswered.
- A static and dynamic pair shares the exact element names, so the runtime view resolves against the structure view.
- One vocabulary owns names across the set; a rename lands in every view in the same edit.
- A scenario traced across views is the cross-check that surfaces missing nodes, inconsistent names, and unsupported behavior.
- A new diagram is admitted by a new question, never a new layout; the set is bounded by question coverage, not a fixed count.

## [10]-[MAINTENANCE]

- Diagram source lives beside the truth it describes and diffs in review alongside the change that can invalidate it.
- Every long-lived diagram names the surface that falsifies it — code path, contract, schema, or decision record.
- Model-first naming governs elements that recur across diagrams: define each once, render many views from that data.
- A diagram whose update reverse-engineers more than it explains is rewritten or deleted.
