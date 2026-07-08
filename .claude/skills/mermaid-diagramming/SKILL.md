---
name: mermaid-diagramming
description: >-
  Generates and validates Mermaid diagrams with YAML frontmatter, ELK layout, Dracula theme
  tokens, and a bundled render-plus-graph-logic validator. Owns diagram methodology — when to
  diagram, node and edge selection, per-type construction, logical soundness — the standard
  archetype catalog (architecture spine, package seam graph, logic flow, state lifecycle, wire
  sequence, persistence schema, dependency strata, schedule, board, history, topology,
  landscape, event flow, profile, decomposition), and the admitted type registry: flowchart,
  sequence, state, class, ER, gantt, mindmap, timeline, kanban, gitGraph, requirement, C4, and
  architecture. Use when authoring, editing, or fixing any mermaid fence, choosing a diagram
  type, or whenever a task asks to draw, diagram, map, or visualize a system, flow, state
  machine, sequence exchange, database schema, dependency structure, schedule, hierarchy, or
  workflow board — even when mermaid is never named — distinct from quantitative dataviz marks
  (charts of data) and interactive HTML pages.
---

# [MERMAID_DIAGRAMMING]

Every committed diagram answers one written question, instantiates one catalog archetype or admitted type, opens with frontmatter carrying its type's Dracula subset, and ships only after the validator and the soundness audit pass. The reasoning discipline and the engine surface load on demand through the reference routes below.

## [01]-[QUESTION]

A diagram earns its fence only when the reader traces a relation across more marks than a clause holds: three or more nodes with at least one branch, cycle, or crossing relation. Below that threshold prose owns the fact, and one diagram owns one question — a diagram needing two legends is two diagrams. The full discipline — investigation traces per archetype, staged growth with the node-annotation-omission ladder, node and edge law, type selection, soundness, multi-diagram composition — is [references/methodology.md](references/methodology.md); what each type's marks must mean, its signal, and its master patterns is [references/construction.md](references/construction.md).

## [02]-[CATALOG]

Select the archetype by intent, copy its template, and refill — a catalog template is self-sufficient, carrying its archetype's construction law in its own prose. An intent outside the catalog selects its type through the methodology decision table and the extended registry, under the same frontmatter, theming, and validation law. The split move partitions a subject the moment a second question appears, and a required legend is itself a split signal.

| [INDEX] | [ARCHETYPE]   | [INTENT]                    | [DECLARATION]       | [SPLIT_MOVE]                     |
| :-----: | :------------ | :-------------------------- | :------------------ | :------------------------------- |
|  [01]   | spine         | main path through owners    | `flowchart LR`      | split at the readiness gate      |
|  [02]   | seam-graph    | shapes across a boundary    | `flowchart LR`      | partition by counterpart package |
|  [03]   | logic-flow    | one operation dispatch      | `flowchart LR`      | extract an arm subflow           |
|  [04]   | lifecycle     | guarded state transitions   | `stateDiagram-v2`   | nest a composite state           |
|  [05]   | wire-sequence | ordered boundary exchange   | `sequenceDiagram`   | split by interaction phase       |
|  [06]   | schema        | persistent entity relations | `erDiagram`         | split by aggregate root          |
|  [07]   | strata        | layer dependency direction  | `flowchart TB`      | collapse peer layers             |
|  [08]   | schedule      | dated committed work        | `gantt`             | split by phase                   |
|  [09]   | board         | stage-held work now         | `kanban`            | split by workflow segment       |
|  [10]   | history       | branch and merge truth      | `gitGraph LR:`      | split by release train           |
|  [11]   | topology      | deployables and reach       | `architecture-beta` | split by zone                    |
|  [12]   | landscape     | one-zoom system landscape   | `C4Context`         | re-declare at the next zoom      |
|  [13]   | event-flow    | command-event causality     | `eventmodeling`     | split by stream                  |
|  [14]   | profile       | two-subject capability compare | `radar-beta`     | one comparison per fence         |
|  [15]   | decomposition | weighted whole-to-part      | `treemap-beta`      | aggregate the tail               |

- [01]-[SPINE](templates/spine.mmd.md)
- [02]-[SEAM-GRAPH](templates/seam-graph.mmd.md)
- [03]-[LOGIC-FLOW](templates/logic-flow.mmd.md)
- [04]-[LIFECYCLE](templates/lifecycle.mmd.md)
- [05]-[WIRE-SEQUENCE](templates/wire-sequence.mmd.md)
- [06]-[SCHEMA](templates/schema.mmd.md)
- [07]-[STRATA](templates/strata.mmd.md)
- [08]-[SCHEDULE](templates/schedule.mmd.md)
- [09]-[BOARD](templates/board.mmd.md)
- [10]-[HISTORY](templates/history.mmd.md)
- [11]-[TOPOLOGY](templates/topology.mmd.md)
- [12]-[LANDSCAPE](templates/landscape.mmd.md)
- [13]-[EVENT-FLOW](templates/event-flow.mmd.md)
- [14]-[PROFILE](templates/profile.mmd.md)
- [15]-[DECOMPOSITION](templates/decomposition.mmd.md)

## [03]-[VALIDATE]

A diagram is not done until its fence passes both stages: graph-logic checks over the source, then a render whose proof is an actual SVG artifact, never a zero exit alone.

```bash
uv run scripts/validate_mermaid.py <file.md ...>
```

Each fence emits `file:line: STATUS check detail` rows with check kinds `render`, `frontmatter`, `contract`, `logic`, `setup`, `read`, and `collect`; `--json` emits identical-key NDJSON for tooling. Contract, logic, and frontmatter rows fire only on findings — a clean fence prints its render row alone, and silence from a check is a pass. Graph-logic analysis covers flowchart, state, sequence, ER, class, gantt, requirement, architecture, and C4; any other family emits a `logic-unimplemented` warn instead of silent approval. Logic failures block: orphan node, unreachable state, undefined or unknown class targets, dangling task, group, service, or relation references. Logic warns demand a split or a stated reason: duplicate same-label edges, orphan participants, entities, services, and requirements. Contract warnings cover accessibility presence and order, `theme: base`, the flat-look lock (`look: classic`, `useGradient`, `dropShadow`), the mono-stack floors, `clusterBkg`, label backing, canonical classes, linkStyle index drift, semantic edge rails, sequence grouping, and palette drift including translucent-alpha discipline. `--no-render` runs the logic and frontmatter checks alone for a fast loop; the process exits nonzero when any fence fails. A render failure splits `syntax` from `environment`, so a missing browser never masquerades as a broken diagram.

The canon checker runs beside the validator as `uv run scripts/check_canon.py <file.md ...>` — a render-free, table-driven enforcement of the theming, styling, and config canon per family (palette closure, alpha tiers, yellow law, micro-scale stamps, per-family floors) emitting the same `file:line: STATUS canon rule detail` row shape with `--json` NDJSON and a nonzero exit on any fail. `--explain <rule-id>` prints a finding's canon sentence and owning reference.

The renderer is `mmdc`, provided on PATH by the machine toolchain (Nix `mermaid-cli` with a pinned Chromium) and preferred from a `pnpm exec mmdc` workspace when a `pnpm-lock.yaml` roots the run; `--renderer CMD` overrides both. Rendering targets the pinned Chromium through `PUPPETEER_EXECUTABLE_PATH`; the real Google Chrome app is never launched.

## [04]-[CONTRACT]

- Frontmatter opens every fence body before the diagram header, carrying `theme: base` and `look: classic` with the Dracula variable subset the diagram type consumes; the token system, role map, dual-host law, and the types and hosts that carry a local style law instead — packet, C4 element surfaces, host-themed docs — are [references/theming.md](references/theming.md).
- Every themed fence renders flat by construction: `look: classic`, `useGradient: false`, `dropShadow: "none"`, and the family `themeCSS` filter belt kill gradient borders and node halos on every host, including one that initializes a newer look — the border canon in the theming reference owns the lock, the weight ladder, and the Lavender container boundary.
- `accTitle` and `accDescr` follow the header on every committed diagram, stating the relation the diagram encodes so the exported SVG stays usable outside its source; `block`, `mindmap`, `sankey`, and `venn` refuse the directives, so there the relation sentence sits beside the fence.
- Node and edge labels carry concept names, never mechanism detail — the owning page carries the bytes.
- Semantic node classes and edge rails come from the canonical Dracula `classDef` set with its ruled translucent accent fills; an ad-hoc hex is a defect.
- The ruled mono stack `fontFamily: "SF Mono, Menlo, Cascadia Mono, Segoe UI Mono, Consolas, monospace"` and the recessed `#21222C` label backing reach every themed fence; per-element sizes ride the theming micro-scale `themeCSS` stamps, and no canvas text renders below 12px.

## [05]-[LEGIBILITY]

Legibility bounds a diagram, not syntax capacity. A rendered diagram ships only after it passes every legibility check:

- Labels render untruncated.
- Edges do not visually dominate nodes.
- Orientation matches reading order.
- Node groups stay visually separable.
- Contrast survives both light and dark hosts.
- The diagram type matches the subject.

A faulted fence converges on its own source across at most five render-inspect-edit rounds; each correction is a minimal text edit to the fence itself, never a sibling file.

## [06]-[REFERENCES]

- [01]-[METHODOLOGY](references/methodology.md): when to diagram, investigation, node and edge law, type selection, soundness audit, multi-diagram composition
- [02]-[CONSTRUCTION](references/construction.md): per-type construction — the question each type answers, what its marks assert, failure modes, truth tests
- [03]-[THEMING](references/theming.md): Dracula palette, role map, the base theme block, canonical classDef rails, dual-host contrast, Alucard
- [04]-[STYLING](references/styling.md): the full styling grammar — every link and arrow form for every family, link lengths, the complete shape registry, containers and subgraphs, style precedence with its interaction traps, the per-type styling matrix
- [05]-[CONFIG](references/config.md): frontmatter schema, secure keys, layout engines and ELK tuning, look system, accessibility, mmdc and CI, trap list
- [06]-[SYNTAX_CORE](references/syntax-core.md): advanced flowchart, sequence, state, class, and ER — node metadata, edge IDs, markdown strings, KaTeX, per-type traps
- [07]-[SYNTAX_EXTENDED](references/syntax-extended.md): the type registry beyond the core five — admitted rows with working fences and traps, registered rows named

## [07]-[GOTCHAS]

- Frontmatter owns initialization; a fence opening with `%%{init:...}%%` converts to frontmatter.
- Reserved words `end`, `default`, `subgraph`, `class` break node IDs — quote the label, rename the ID.
- `layout: elk` outside flowchart needs a host-registered loader and has no dagre fallback — only flowchart fences declare it.
- Edge labels containing `[`, `]`, or `:` need double quotes: `A -->|"[WIRE]: shape"| B`.
- Extended-family fences validate whenever touched.

## [08]-[REPO_INTEGRATION]

When the host repo declares a docs gate, that gate consumes `scripts/validate_mermaid.py --json`; the bundled script is the same engine everywhere else.
