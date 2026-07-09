# [STRUCTURE]

Universal information-structure law: no document kind owns these concerns — a readme instantiates routing, an architecture doc instantiates representation, a work ledger instantiates marker systems — and any doc-set maps onto the same tiers. The concern is the law; the filename is incidental.

## [01]-[ALTITUDE]

A fact lands at the lowest tier that owns it; a higher tier states only the invariant the fact instantiates. A sentence that can move one tier down without losing governing force over more than one child is at the wrong altitude. The failure is two-sided: prose pinned below its tier freezes mechanism a rebuild must be free to re-derive, and prose floated above its tier dissolves into a platitude no rebuild can act on — a sentence whose deletion changes no rebuild fails admission at every tier.

- [CORPUS_ROOT]: Purpose, layer law, entry routes by concern — never inventories of anything below.
- [AREA_INDEX]: Area invariants, unit-grain topology and boundaries, admission law — never a unit's member roster or file names.
- [UNIT_INDEX]: Unit charter, sub-structure as a fenced representation, unit-grain seams, registries the unit owns — never wire byte-truth, signatures, or literals.
- [IMPLEMENTATION_PAGE]: Mechanism, signatures, byte-truth, literals, one owner's flow — never higher law restated or sibling pages re-taught.
- [WORK_ITEM]: Scoped intent, integration points, growth pressure — never design content or settled law.
- [IN_CODE]: One in-situ constraint the code cannot show — never anything else.

[DEMOTION] — Land the fact at its owner first, then collapse the higher copy to the invariant it instantiates; payload dropped during demotion is a defect.

## [02]-[ROUTING]

Routing is the one job that licenses linking and naming siblings; every other page composes settled law silently.

- One router per corpus level, keyed by reader decision: each recurring choice maps to exactly one owning page. A missing route row is a missing capability; a duplicate route is a fork.
- A route row is path, label, and one charter phrase — never signatures, member inventories, fault bands, or package decisions. A row needing a sentence is a card with earned fields, not a wider row.
- A router scales by grouping: when the unit spans multiple sub-folders, cards group under one `[FOLDER_TOKEN]:` label per folder — each folder reads as its own card block, and the group labels mirror the disk folders exactly. A small unit keeps one flat card list; group labels are earned by the second folder, never decorative.
- Navigation below the route pointer is disk truth: the tree is the page index, and adding a leaf costs zero router edits.
- Non-router pages never relink or re-teach siblings: mechanics at the owning page, consequence at the consumer, the boundary fixed in one pointer line.

## [03]-[REPRESENTATION]

Choose the container by what the reader retrieves; convert before styling.

[CONTAINERS]:
- Prose carries law; a list carries parallel atomic items; a card — key plus earned field lines — carries a decision cluster; a table carries atomic lookup facts crossed row-by-column; a tree or diagram carries structure and relations. Tables enumerate, cards legislate.
- A bullet is one atomic entry — one fact, one rule, one member. A closed token set referenced rather than defined rides inline after its group label on one line; the list form is earned only when members carry per-member content.
- An entry carries one decision in one to two sentences, three at the hard cap; past the cap the entry is hiding a card, a labeled block, or section prose. Closed enumerations whose payload is the roster itself are registry entries and legal at length.
- A representation is declared regenerable, verified by tooling where a verifier exists, and never paraphrased back into prose — the paraphrase is a second copy that drifts.
- Graphical labels carry concept names only: a node, edge, or tree-entry label stays under ten words, and code detail never rides a tree, seam edge, or diagram label.
- Diagram fences — question admission, type selection, construction, render validation — ride the mermaid-diagramming skill; a doc admits one only as a declared regenerable representation.

[FENCE_CONTENT]:
- A fence carries a language tag plus one intent label from the closed set — `copy-safe` runs as written, `template` carries neutral placeholders, `conceptual` illustrates, `generated` and `output-only` carry produced output, `rejected` carries a counterexample — and the body honors its label: a copy-safe body runs, a renderable body renders under the corpus validator.
- Reusable examples use legal neutral identifiers; placeholder strings such as `"<value-a>"` appear only inside literals, and no project, host, or domain concept anchors an example meant to travel.
- Each example owns one demonstration region no sibling example repeats, and shows the form at real composed scale — admission, dispatch, and policy in one body with the growth axis visible — never an isolated minimum.

[TABLE_ELIGIBILITY] — Build a table only when all three hold: rows share one comparison question, every column answers it with an atomic value, and more than one row exists. A single prose column disqualifies the table outright; a one-row table is a definition record; rows with no shared question are separate records. Eligibility is structural, never an enumeration license: rows mirroring an owner recorded elsewhere are a stale mirror however atomic the cells; the doc tables only its own registry or a verified representation.

[CELL_BUDGET] — Each cell is one atomic unit: a value, marker, token, code span, proper noun, path, or a phrase of at most six words carrying no internal comma or clause-joining conjunction. A cell that wants a comma wants to be a card; a cell that wraps to a second rendered line is over budget. The stub column is a short unique key, never a sentence.

[HEADER_COMPRESSION] — Hoist every word the cells repeat into the header before writing cells; no cell restates its header, repeats another cell, or carries a value shared by the whole column — a shared value moves to the lead sentence. Cross-row invariants and reading rules live in the lead before the table, never duplicated per cell.

[TABLE_MECHANICS] — Enumerable tables open with a centered `[INDEX]` column numbered `[01]` through `[NN]`; every header is a bracketed uppercase rubric; links live in a routing list after the table, never in cells beside prose columns.

[TABLE_REFACTOR] — Repairing an existing table: test eligibility first (a failed test converts the whole table, never trims it), hoist repeated words to headers, split sentence-bearing rows to cards, extract links to field lines.

```markdown rejected
| Mode | When to use it | Output |
| --- | --- | --- |
| interview | Use when requirements are ambiguous, contradictory, or live in the user's head — see [modes.md](modes.md) | a decisions table plus an implementation-ready prompt |
```

```markdown accepted
| [INDEX] | [MODE]      | [TRIGGER]                          | [OUTPUT]          |
| :-----: | :---------- | :--------------------------------- | :---------------- |
|  [01]   | `interview` | requirements ambiguous or unstated | `decisions-table` |
```

## [04]-[HEADERS_AND_LEADS]

The header set and the first lines are the highest-value signal an agent loads; both are engineered, never accumulated.

[HEADERS]:
- Headers form a closed, consistent vocabulary across sibling documents of one kind — same tokens, same order, same zero-padded numbering — so a machine can census them and an agent predicts the shape before opening the file.
- A section exists only where it owns a decision cluster; a header that groups nothing is deleted, not filled.
- Headers absorb what their content repeats: entries that each begin with the same word belong under a header carrying that word once.

[LEADS]:
- The lead is one charter sentence plus at most one boundary-consequence sentence, opening with the document's own law — never the doc-set, the siblings, the audience, or the process.
- A lead needing semicolons or parenthetical inventories is carrying a lower tier's payload; intro material earns its slot by changing the reader's next action.

```markdown rejected
This package's README routes its design pages and registers its packages; `ARCHITECTURE.md` carries the domain map (six sub-domains: ingestion, registration, deviation, reconstruction, analysis, costing), and the tessellation daemon streams per-element output over the sync rail as checksum-framed rows keyed by the content hash.
```

```markdown accepted
`<unit>` owns host-free geometry capability: evidence graduation, scan processing, and the tessellation rail that serves every cross-boundary consumer.
```

## [05]-[SIGNAL_SELECTION]

What an index-tier page carries is a selection decision, made for the agent editing the unit in isolation.

- Closed signal bands, nothing else: the router, the registries the page owns, and the unit's boundary and refusal seams. Provider inventories collapse to registry cards, cross-owner consequences to seam rows, implementation mechanics to the owning page.
- The test for a candidate sentence: an agent lands here with no other context — the line changes what it edits, admits, or refuses, or it is deleted. Topology narration, sibling-role description, and provenance never pass.
- Consistency beats local optimality: an index deviating from its siblings' shape to say something extra has misplaced the extra — the shape is the contract, and the extra belongs to its owner.

## [06]-[FILE_KIND_CONSISTENCY]

A recurring file kind carries one declared schema — section set, marker vocabulary, entry shape — and every instance conforms byte-structurally. Uniformity is what makes a corpus machine-censusable and lets an agent work any instance without relearning its shape; a locally-optimized deviation is a defect even when it reads better in isolation.

- The schema declares: the exact header set in order, the entry/card shape with its closed field vocabulary, the marker vocabulary, and the one sanctioned extension point if any.
- A structural census is the conformance gate: identical header tokens across instances, identical field sets per entry, zero undeclared markers. A file kind whose instances cannot be censused has no schema — write one before writing another instance.
- New capability lands as a row, entry, or declared extension inside the schema, never as a novel section invented per instance; pressure for a new section is a schema change made at the owner and rolled to every instance.

## [07]-[MARKER_SYSTEMS]

A closed marker vocabulary plus a templated entry shape is the device that keeps many agents consistent inside one file class: the marker carries state, the schema carries structure, and prose carries only law.

- Design: a closed token set declared once by the schema owner, one meaning per token, uppercase bracketed form, machine-greppable — an agent filters the corpus on the exact string.
- Entry leaders compose identity and state (`[<ID>]-[<STATUS>]:`), so an entry's lifecycle is readable and greppable without parsing its body; status transitions are edits to the leader, never narrated in prose.
- Field lines under a leader come from the closed field vocabulary in declared order; a field that decides nothing for this entry is omitted, never filled with filler.
- Compact status glyphs (`[O]` `[X]` `[!]` `[~]`) render only where density matters — checked lists, delta summaries, table cells — with globally declared meanings; a marker never duplicates a field the entry already carries.
- Invocation markers (`[IMPORTANT]`, `[CRITICAL]`, `[ALWAYS]`, `[NEVER]`) weight constraints in instruction files alone; ordinary documentation carries strength through prose modals, and one concept never carries both. Weight is rationed: a page that marks every rule critical re-flattens the hierarchy the markers exist to create.

```markdown accepted
- [0042]-[BLOCKED]: <entry title>
  - Capability: <the higher-order concept this entry lands>
  - Anchors: <the owners that make it plausible>
  - Tension: <the unresolved constraint that blocks it>
```

## [08]-[SCHEMA_OWNERSHIP]

One owner declares a file kind's schema and vocabulary; every instance and every instruction surface composes it silently.

- The owner is the corpus standard closest to the file kind — instances never restate the schema, never re-teach the marker meanings, and never carry a local variant.
- A vocabulary defined in two places is a fork: consolidate to the owner and convert the second site to silence. Scattered partial redefinitions are how a corpus rots — each new instruction surface re-declaring three of seven tokens with new spellings.
- Tooling compiles the schema into pressure — a census gate, a marker grep, a lint — and never invents vocabulary of its own.
