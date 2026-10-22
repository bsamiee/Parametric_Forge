# [<architecture-title-token>]

<architecture-lead-2-3-sentences: the unit's charter in owning voice — what it owns, the one invariant band it lowers onto, and its boundary to the peers it aligns with by contract, never by reference.>

<!-- source-only: scope — governs folder `<package>/ARCHITECTURE.md`. Unused sections omit and survivors renumber — numbering here is the full-set numbering, and an extension section seats after the canonical sections it follows, cited by name because its index moves with the survivors. Folder grain carries every section, [05]-[ROUTING] earned only where the folder owns 3+ extension classes, else its growth law stays on design pages; a folder-grain extension section ([NAMESPACES], [FAULT_REGISTRY]) is earned only by real ownership no canonical section carries. -->

<!-- source-only: diagrams — every committed fence carries exactly one frontmatter `config:` block setting `layout: elk` and `flowchart: {curve: linear, padding: 25}`; themeVariables, themeCSS, theme, classDef, style, linkStyle, and `%%{init}%%` never appear. accTitle and accDescr ride every fence; accDescr states one sentence under 150 columns naming the diagram's question, never its edge or node roster.
  STRATA   `flowchart TB` — one subgraph per stratum, every edge downward labeled `[IMPORT]: SourcedType` (one sourced type per edge), one `forbidden:` edge naming the rejected upward direction. Ruled counter-edges draw dotted `-.->` labeled `[COUNTER]: PayloadType`, earning a seat only where the payload is a value the lower stratum consumes rather than an owner it imports, so the type graph stays acyclic.
  SEAM     `flowchart LR` — home owners in one subgraph, one node per counterpart, edges `[KIND]: shape-name` spelled verbatim from the owning endpoint. Node shape carries the counterpart's ROLE — `{{x}}` bidirectional peer, `([x])` one-way source or sink, `[(x)]` store — while the arrow carries the CONTRACT's direction: a single-headed arrow projects toward the consumer, a double-headed arrow marks a shape both ends mint. Each seam edge collapses every contract between its endpoints at that kind, an instance stating per-edge exceptions only.
  INTERNAL `flowchart TB|LR` — stage or owner nodes in flow order, edge labels naming the carried fact or verb, a subsystem spine reading entry -> transform -> egress. -->

## [01]-[DOMAIN_MAP]

<!-- source-only: codemap — one node per eventual source file in the language's folder and file casing, each `#` tail naming the concept that file owns; tails align within a block under the 150-column cap, carrying no method chain, type roster, or design detail, and a tail that cannot fit aligned trims to its load-bearing concept. -->

```text codemap
core/
├── resolver.py       # mints content keys; owns the resolve dispatch
├── registry.py       # holds the descriptor registry and admission law
└── shape/            # the shape sub-domain owners
    ├── fold.py       # folds shape ops through one entry
    └── codec.py      # decodes shape wire bytes at the seam
```

## [02]-[STRATA]

<!-- source-only: keys run `S0` upward; strata is the only rank vocabulary — wave, band, and tier never name a rank. Member-seating is a flat bullet list: every row keyed `S<N>` (a banded rank `S<N>–S<M>`), one seating decision per row under 150 columns, a stratum carrying more decisions taking sibling keyed rows; rows carry only law the fence cannot show — merged-node resolutions, absent-edge law, cycle prevention, cross-stratum seatings — an edge the diagram labels never restates in a row, and nesting or a prose block never carries a seating. Every tier carries this section. -->

<strata-graph diagram per the STRATA archetype>

<member-seating rows: flat `S<N>`-keyed bullets, one decision each, under 150 columns>

## [03]-[SEAMS]

<!-- source-only: seams are cross-boundary by construction — an in-package relation lives in the codemap or [04]-[INTERNAL], never here; a unit whose cross-boundary seams overflow one clean fence splits by counterpart group into a fence each. -->

<seam-graph diagram per the SEAM archetype: home sub-domain owners in a subgraph, one node per counterpart package>

## [04]-[INTERNAL]

<!-- source-only: interior flow — what travels between the unit's own owners, in what order, under what crossing law. One flowchart per genuine flow spine (a unit with one spine carries one fence); prose states the crossing rules the diagram cannot carry — mint-once delegation, decode-once, lift-at-seam, lowest-stratum homing — deferring exact per-stage wiring to the owning implementation pages. Member rosters, counts, and per-page content mirrors stay on owner pages; this section routes by concept. -->

<internal-flow diagram per the INTERNAL archetype>

<crossing-law prose: the mint-once, decode-once, lift-at-seam, and homing rules the spine obeys>

## [05]-[ROUTING]

<!-- source-only: extension table — each row names one owner surface and the edit shape a new capability lands as: one row, one arm, one case; owner pages carry the full growth law, never restated here. -->

| [INDEX] | [CHANGE]                  | [OWNER_SURFACE] | [SHAPE_OF_THE_EDIT]                     |
| :-----: | :------------------------ | :-------------- | :-------------------------------------- |
|  [01]   | <new-capability-class>    | `<owner-page>`  | <one-row-one-arm-one-case edit>         |
|  [02]   | a new shape refinement op | `shape/fold.md` | one `ShapeOp` case and one dispatch arm |

## [06]-[BOUNDARIES]

<!-- source-only: prohibition retirement — convert a `[PROHIBITIONS]` section, never delete it: each NEVER row becomes either a positive law whose violation is unrepresentable by construction (the owner mechanism seated here) or a `RULINGS.md` row at the narrowest owning tier. Carry the row's discriminant — the fact that decided the prohibition — through the conversion; dropping it loses the law and is the failed form. -->

Boundaries state one positive ownership line each at the unit's own grain: its admitted role, the app-root pin, and the peer-owned concern.

- <unit role: the capability class this unit owns>
- <app-root pin: the composition-root-only binding>
- <peer ownership: the concern a named peer owns through the seam>
