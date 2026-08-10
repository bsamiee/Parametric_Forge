# [<architecture-title-token>]

<architecture-lead-2-3-sentences: the unit's charter in owning voice — what it owns, the one invariant band it lowers onto, and its boundary to the peers it aligns with by contract, never by reference.>

<!-- source-only: scope — governs branch `libs/<lang>/.planning/ARCHITECTURE.md` and folder `<package>/ARCHITECTURE.md`; Tier-0 `libs/.planning/ARCHITECTURE.md` carries the tier-0 spine below in prose-law form, no seam diagram, no [ROUTING]. Unused sections omit and survivors renumber — numbering here is the full-set numbering, and an extension section seats after the canonical sections it follows, cited by name because its index moves with the survivors. Branch grain earns [04]-[INTERNAL] (one flowchart per subsystem spine), [05]-[ROUTING] (the merged extension table), and an [ADMISSION_POLICY] extension after [06]-[BOUNDARIES] — the admission-route law — where no registry owns it; [03]-[SEAMS] stays the cross-runtime registry. Folder grain carries every section, [05]-[ROUTING] earned only where the folder owns 3+ extension classes, else its growth law stays on design pages; a folder-grain extension section ([NAMESPACES], [FAULT_REGISTRY]) is earned only by real ownership no canonical section carries. -->

<!-- source-only: tier-0 spine — the corpus-root topology page carries these sections in this order, each stating law no branch or folder can own; a section with nothing to rule omits and survivors renumber. Every row is prose law and keyed tables, never a diagram, and names a language only where the topology itself does.
  [01] STRATA                    stratification law every branch answers — rank vocabulary, edge abstraction, seating, counter-edges; a package roster seats at its branch.
  [02] DEPENDENCY_DIRECTION      cross-branch direction alone: what a branch resolves with no peer present, what a contract carries; per-owner direction stays at the branch.
  [03] UNIVERSAL_VS_CAPTURE      what a corpus contract defines against what stays branch-local at full richness, the discriminant stated.
  [04] <CONCERN>_FLOW            one owner per runtime for each cross-runtime concern, and the wire where the runtimes meet.
  [05] PLANNING_LIFECYCLE        where design pages live, what a mature folder carries instead, and when the scaffold dissolves.
  [06] PER_LANGUAGE_ROLES        the domain each branch estate carries, under peer independence — no branch ranks, gates, or precedes another.
  [07] CROSS_LANGUAGE_WIRE       the contract registry, one entry per contract class, each class carrying its producer law and its drift defect.
  [08] OBSERVABILITY_CONFORMANCE cross-runtime signal rows transcribed identically in meaning, with the branch owner that repairs a drifted row.
  [09] SCHEMA_STATE              the state contract each branch mints alone, and what composition merges at the application root.
  [10] CONSUMPTION_MODEL         the deployment-shape axis roster: closed axes fix their vocabulary here, an open axis fixes the descriptor shape alone and grows at its supplying branch, and a value an owner assumes at compile time is the defect the roster forecloses.
  [11] DESIGN_LANGUAGE           the shape invariants every estate shares so disparate packages read as one system, each row routing its spelling to the language doctrine.
  [12] ADMISSION                 the rung ladder new capability climbs — row, adapter, page, sub-domain, package, host boundary, branch — each rung's earn-test stated.
  [13] APPEARANCE                the surface-appearance documents crossing the runtimes, their producers, and the one frozen vocabulary each transcribes.
  [14] EVENT_FABRIC              the event envelope every branch mints alone — the specification owns the semantics, an SDK accelerates, and grammar, roster, format, and binding stay data.
-->

<!-- source-only: tier-0 voice — a section states the invariant and its extension rule, never a branch's member roster, package registry, or file names; the narrowest tier owning a fact keeps it, and Tier-0 keeps only what spans branches. -->

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
