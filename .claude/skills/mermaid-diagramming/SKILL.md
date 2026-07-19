---
name: mermaid-diagramming
description: >-
    Generates and validates Mermaid diagrams with YAML frontmatter, ELK layout, Dracula theme
    tokens, and a bundled render, graph-logic, and SVG-geometry validator. Owns diagram methodology — when to
    diagram, node and edge selection, per-type construction, logical soundness — the archetype
    template catalog from architecture spine to weighted decomposition, the concept-to-diagram
    map that turns state machines, dispatch topologies, dependency graphs, protocol seams, and
    chronologies into the right fence, and the embedding contract for diagrams inside markdown
    docs and single-file HTML artifacts. Use when authoring, editing, or fixing any mermaid
    fence, choosing a diagram type, embedding a rendered diagram in a page, or whenever a task
    asks to draw, diagram, map, or visualize a system, flow, state machine, sequence exchange,
    schema, dependency structure, schedule, hierarchy, or workflow board — even when mermaid is
    never named — distinct from quantitative dataviz marks and interactive HTML pages.
---

# [MERMAID_DIAGRAMMING]

Every committed diagram answers one written question, instantiates one catalog archetype or admitted type, opens with frontmatter carrying its type's Dracula subset, and ships only after the validator and the soundness audit pass. Reasoning discipline and engine surface load on demand through the reference routes below.

## [01]-[ROUTING]

- [01]-[METHODOLOGY](references/methodology.md): admission, investigation, node/edge law, type selection, soundness audit, multi-diagram composition
- [02]-[CONSTRUCTION](references/construction.md): per-type — each type's question, what its marks assert, failure modes, truth tests
- [03]-[THEMING](references/theming.md): Dracula palette, role map, the base theme block, canonical classDef rails, dual-host contrast, Alucard
- [04]-[STYLING](references/styling.md): link/arrow forms, link lengths, shape registry, containers, subgraphs, precedence traps, per-type matrix
- [05]-[CONFIG](references/config.md): frontmatter schema, secure keys, layout engines, ELK tuning, look system, accessibility, mmdc and CI, traps
- [06]-[SYNTAX_CORE](references/syntax-core.md): flowchart, sequence, state, class, ER — node metadata, edge IDs, markdown strings, KaTeX, traps
- [07]-[SYNTAX_EXTENDED](references/syntax-extended.md): beyond the core five — admitted rows with working fences and traps, registered rows named
- [08]-[CONCEPT_MAP](references/concept-mapping.md): shape in code, prose, plans, arguments: signals, archetype routes, misfit shapes, composites
- [09]-[EMBEDDING](references/embedding.md): fence law in markdown hosts, inline-SVG law in single-file HTML, export surfaces, source-beside-render

## [02]-[QUESTION]

A diagram earns its fence only when the reader traces a relation across more marks than a clause holds: three or more nodes with at least one branch, cycle, or crossing relation. Below that threshold prose owns the fact, and one diagram owns one question — a diagram needing two legends is two diagrams. Full authoring discipline is [references/methodology.md](references/methodology.md), and per-type mark law is [references/construction.md](references/construction.md). A subject that arrives as raw material — code, prose, a plan, an argument — with no written question resolves its shape first through [references/concept-mapping.md](references/concept-mapping.md).

## [03]-[CATALOG]

Select the archetype by intent, copy its template, and refill — a catalog template is self-sufficient, carrying its archetype's construction law in its own prose. An intent outside the catalog selects its type through the methodology decision table and the extended registry, under the same frontmatter, theming, and validation law. A split move partitions a subject the moment a second question appears, and a required legend is itself a split signal.

| [INDEX] | [ARCHETYPE]                                     | [INTENT]                       | [DECLARATION]       | [SPLIT_MOVE]                     |
| :-----: | :---------------------------------------------- | :----------------------------- | :------------------ | :------------------------------- |
|  [01]   | [SPINE](templates/spine.mmd.md)                 | main path through owners       | `flowchart LR`      | split at the readiness gate      |
|  [02]   | [SEAM_GRAPH](templates/seam-graph.mmd.md)       | shapes across a boundary       | `flowchart LR`      | partition by counterpart package |
|  [03]   | [LOGIC_FLOW](templates/logic-flow.mmd.md)       | one operation dispatch         | `flowchart LR`      | extract an arm subflow           |
|  [04]   | [LIFECYCLE](templates/lifecycle.mmd.md)         | guarded state transitions      | `stateDiagram-v2`   | extract the composite lifecycle  |
|  [05]   | [WIRE_SEQUENCE](templates/wire-sequence.mmd.md) | ordered boundary exchange      | `sequenceDiagram`   | split by interaction phase       |
|  [06]   | [SCHEMA](templates/schema.mmd.md)               | persistent entity relations    | `erDiagram`         | split by aggregate root          |
|  [07]   | [STRATA](templates/strata.mmd.md)               | layer dependency direction     | `flowchart TB`      | collapse peer layers             |
|  [08]   | [SCHEDULE](templates/schedule.mmd.md)           | dated committed work           | `gantt`             | split by phase                   |
|  [09]   | [BOARD](templates/board.mmd.md)                 | stage-held work now            | `kanban`            | split by workflow segment        |
|  [10]   | [HISTORY](templates/history.mmd.md)             | branch and merge truth         | `gitGraph LR:`      | split by release train           |
|  [11]   | [TOPOLOGY](templates/topology.mmd.md)           | deployables and reach          | `architecture-beta` | split by zone                    |
|  [12]   | [LANDSCAPE](templates/landscape.mmd.md)         | one-zoom system landscape      | `C4Context`         | re-declare at the next zoom      |
|  [13]   | [EVENT_FLOW](templates/event-flow.mmd.md)       | command-event causality        | `eventmodeling`     | split by stream                  |
|  [14]   | [PROFILE](templates/profile.mmd.md)             | two-subject capability compare | `radar-beta`        | one comparison per fence         |
|  [15]   | [DECOMPOSITION](templates/decomposition.mmd.md) | weighted whole-to-part         | `treemap-beta`      | aggregate the tail               |

## [04]-[VALIDATE]

A diagram is not done until its fence passes both stages: graph-logic checks over the source, then a render whose proof is an actual SVG artifact, never a zero exit alone.

```bash template
uv run scripts/validate_mermaid.py <file.md ...>
```

Each fence emits `file:line: STATUS check detail` rows with check kinds `render`, `legibility`, `frontmatter`, `contract`, `logic`, `export`, `proof`, `setup`, `read`, and `collect`; `--json` emits identical-key NDJSON for tooling. Contract, logic, legibility, and frontmatter rows fire only on findings — a clean fence prints its render row alone, and silence from a check is a pass. Graph-logic analysis covers the families the validator implements; any family outside that set emits a `logic-unimplemented` warn instead of silent approval. A logic failure blocks on a structural break the graph cannot resolve, and a logic warn demands a split or a stated reason; the emitted row names the exact condition. Contract warnings enforce the theming, styling, and config canon per family. `--no-render` runs the logic and frontmatter checks alone for a fast loop; the process exits nonzero when any fence fails. A render failure splits `syntax` from `environment`, so a missing browser never masquerades as a broken diagram. After a fence renders, the `legibility` pass parses the SVG geometry for the graph families (flowchart, state, ER, class) and emits `node-overlap` (fail), `edge-over-node`, and `edge-crossing-pairs:N` rows — N counts crossing edge pairs, a lower bound, computed from node bounding boxes and edge routing rather than eyeballed; sequence, gantt, and quantitative families carry inherent crossings and are exempt.

`uv run scripts/check_canon.py <file.md ...>` runs the canon checker beside the validator — a render-free, table-driven enforcement of the theming, styling, and config canon per family emitting the same `file:line: STATUS canon rule detail` row shape with `--json` NDJSON and a nonzero exit on any fail. `--explain <rule-id>` prints a finding's canon sentence and owning reference.

Renderer resolution walks the workspace first — `node_modules/.bin/mmdc` from any cwd ancestor, then PATH `mmdc`, `--renderer CMD` overriding both. Each render binds the pinned Chromium through the generated puppeteer-config `executablePath`, so the real Google Chrome app never launches. A fence the resolved renderer rejects re-proves through the pinned release renderer the validator invokes over the pnpm dlx cache, verified by the emitted SVG — so a lagging toolchain never masquerades as broken syntax; the passing row lands as `rendered-release:`, and a fence the pinned renderer also rejects stays a real syntax failure. `--export DIR` writes every passing fence as an embed-ready SVG — unique root id, aria title and description preserved, Dracula canvas baked — the mechanical arm of the embedding contract. `--proof` rasterizes each rendered SVG browserlessly through resvg into a per-run ephemeral dir cleaned on exit — `--keep` preserves it and prints `proof-dir:` — with mmdc's own PNG as the fallback where a family still carries `foreignObject` labels; a proof failure lands as a typed `proof` row, never a silent pass.

## [05]-[CONTRACT]

- Frontmatter opens every fence body above the diagram header, carrying `theme: base` and `look: classic` with the Dracula subset its type consumes; a fence opening with `%%{init:...}%%` converts to frontmatter.
- Local style law replaces that subset on `packet`, C4 element surfaces, and host-themed docs.
- Token system, role map, and dual-host law are [references/theming.md](references/theming.md).
- Every themed fence renders flat by construction: `look: classic`, `useGradient: false`, `dropShadow: "none"`, and the family `themeCSS` filter belt.
- Flat construction kills gradient borders and node halos on every host, including one that initializes the neo look.
- Theming's border canon owns the lock, the weight ladder, and the Lavender container boundary.
- `accTitle` and `accDescr` follow the header on every committed diagram, stating the encoded relation so the exported SVG reads outside its source.
- `block`, `mindmap`, `sankey`, and `venn` refuse the directives, `ishikawa` mis-handles them as nodes, and `kanban` as columns, so their relation sentence sits beside the fence; `timeline` and `eventmodeling` parse them but emit nothing into the SVG, so their relation sentence rides beside the fence too.
- Node and edge labels carry concept names, never mechanism detail — the owning page carries the bytes.
- Semantic node classes and edge rails ride the canonical Dracula `classDef` set with its ruled translucent accent fills; an ad-hoc hex is a defect.
- Flowchart edge rails bind insertion-stably through `eN@` edge-id classes; positional `linkStyle` indices drift on every insertion.
- One `animate: true` edge per diagram may mark a genuinely live, streaming, or hot path with its semantic stated; unmotivated animation is a defect, and a raster export stills it.
- Theming's ruled mono stack and the recessed `#21222C` label backing reach every themed fence, and no canvas text renders below 12px through the micro-scale `themeCSS` stamps.

## [06]-[LEGIBILITY]

Legibility bounds a diagram, not syntax capacity. A rendered diagram ships only after the validator's geometry rows clear and the reviewer clears what geometry cannot — untruncated labels, reading-order orientation, light/dark host contrast, type matching subject. A faulted fence converges on its own source across at most five render-inspect-edit rounds; each correction is a minimal text edit to the fence itself, never a sibling file.

## [07]-[REPO_INTEGRATION]

When the host repo declares a docs gate, that gate consumes `scripts/validate_mermaid.py --json`; the bundled script is the same engine everywhere else.
