# [<architecture-title-token>]

<architecture-lead-2-3-sentences: the unit's charter in owning voice — what it owns, the one invariant band it lowers onto, and its boundary to the peers it aligns with by contract, never by reference.>

<!-- source-only: scope — this template governs the branch `libs/<lang>/.planning/ARCHITECTURE.md` and folder `<package>/ARCHITECTURE.md` altitudes; Tier-0 `libs/.planning/ARCHITECTURE.md` keeps its prose-law form and takes no seam diagram and no [ROUTING]. Unused sections omit and survivors renumber, so canonical numbering here is the full-set numbering. Branch grain earns [04]-[INTERNAL] (one flowchart per subsystem spine) and [05]-[ROUTING] (the merged extension table); [03]-[SEAMS] stays the cross-runtime registry. Folder grain carries every section, and [05]-[ROUTING] is earned only where the folder owns 3+ extension classes, else its growth law stays on design pages. Branch grain also earns [06]-[ADMISSION_POLICY] — the admission-route law — where no registry owns it; a folder-grain extension section ([NAMESPACES], [FAULT_REGISTRY]) is earned only by real ownership no canonical section carries. -->

<!-- source-only: diagram convention — every committed fence carries exactly one frontmatter `config:` block setting `layout: elk` and `flowchart: {curve: linear, padding: 25}`, nothing more. -->

<!-- source-only: NO themeVariables, themeCSS, theme, classDef, style, linkStyle, or %%{init}%% — theming is a render-time concern the mermaid-diagramming skill owns; accTitle and accDescr are required on every fence, and accDescr is one sentence under 150 columns naming the diagram's question, never its edge or node roster. -->

<!-- source-only: STRATA archetype uses `flowchart TB`, one subgraph per stratum, every edge downward labeled `[IMPORT]: SourcedType` (one sourced type per edge), one `forbidden:` edge naming the rejected upward direction. -->

<!-- source-only: SEAM archetype uses `flowchart LR`, home owners in one subgraph, one node per counterpart, edges `[KIND]: shape-name` spelled verbatim from the owning endpoint, node shape carrying direction — `{{x}}` bidirectional peer, `([x])` one-way source or sink, `[(x)]` store. A seam edge collapses every contract between its endpoints at that kind; an instance states per-edge exceptions only, never the convention. -->

<!-- source-only: INTERNAL archetype uses `flowchart TB|LR`, stage or owner nodes in flow order, edge labels naming the carried fact or verb, a subsystem spine reading entry -> transform -> egress. -->

## [01]-[DOMAIN_MAP]

A codemap is the unit's file index: one node per eventual source file in the language's folder and file casing, each `#` tail naming the concept that file owns. Tails align within a block under the 150-column cap, carrying no method chain, type roster, or design detail; a tail that cannot fit aligned is trimmed to its load-bearing concept.

```text codemap
core/
├── resolver.py       # mints content keys; owns the resolve dispatch
├── registry.py       # holds the descriptor registry and admission law
└── shape/            # the shape sub-domain owners
    ├── fold.py       # folds shape ops through one entry
    └── codec.py      # decodes shape wire bytes at the seam
```

## [02]-[STRATA]

Strata rank the unit interior: keys run `S0` upward and strata is the only rank vocabulary — wave, band, and tier never name a rank. One subgraph per stratum, every consumption edge pointing down and naming one sourced type, one forbidden upward edge. Member-seating is a flat bullet list — every row keyed `S<N>` (a banded rank keys `S<N>–S<M>`), one seating decision per row under 150 columns, a stratum carrying more decisions taking sibling keyed rows; rows carry only law the fence cannot show — merged-node resolutions, absent-edge law, cycle prevention, cross-stratum seatings. An edge the diagram labels never restates in a row, and nesting or a prose block never carries a seating. Every altitude carries this section, and the diagram follows the STRATA archetype.

<strata-graph diagram: one subgraph per stratum, downward `[IMPORT]: SourcedType` edges, one `forbidden:` upward edge>

<member-seating rows: flat `S<N>`-keyed bullets, one decision each, under 150 columns>

## [03]-[SEAMS]

A seam is cross-boundary by construction: an in-package relation is never a seam and lives in the codemap or the `[04]-[INTERNAL]` diagram. Each edge is one contract labeled `[KIND]: shape-name`, and a unit whose cross-boundary seams overflow one clean fence splits by counterpart group into a fence each.

<seam-graph diagram: home sub-domain owners in a subgraph, one node per counterpart package, edges kinded and node shapes directional>

## [04]-[INTERNAL]

Interior flow is what travels between the unit's own owners, in what order, under what crossing law. One flowchart per genuine flow spine — a unit with one spine carries one fence — and prose states the crossing rules the diagram cannot carry: mint-once delegation, decode-once, lift-at-seam, lowest-stratum homing. Member rosters, counts, and per-page content mirrors stay on owner pages; this section routes by concept.

<internal-flow diagram: stage or owner nodes in flow order, entry -> transform -> egress, edge labels naming the carried fact or verb>

<crossing-law prose: the mint-once, decode-once, lift-at-seam, and homing rules the spine obeys, deferring exact per-stage wiring to the owning implementation pages>

## [05]-[ROUTING]

Routing is the extension table: each row names one owner surface and the edit shape a new capability lands as — one row, one arm, one case. Owner pages carry the full growth law; this table never restates it.

| [INDEX] | [CHANGE]                  | [OWNER_SURFACE] | [SHAPE_OF_THE_EDIT]                     |
| :-----: | :------------------------ | :-------------- | :-------------------------------------- |
|  [01]   | <new-capability-class>    | `<owner-page>`  | <one-row-one-arm-one-case edit>         |
|  [02]   | a new shape refinement op | `shape/fold.md` | one `ShapeOp` case and one dispatch arm |

## [06]-[BOUNDARIES]

Boundaries state one line each at the unit's own grain: what the unit is not, which pin stays at the app root, which concern a peer owns.

- <unit-negation: the neighbouring package classes this unit is not>
- <app-root pin: the composition-root-only binding that never sinks into the lib>
- <peer ownership: the concern a named peer owns, reached only through the seam>

## [07]-[PROHIBITIONS]

Deleted patterns the owner regions foreclose, each line naming the mechanism that forecloses it:

- NEVER <forbidden form>; <owner mechanism> forecloses it by construction.
- NEVER a second owner for <concern>; <canonical owner> holds it alone.
