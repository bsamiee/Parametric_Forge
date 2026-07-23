# [DELIVERABLES]

Each deliverable type is a fixed composition: a layout class from the style reference, a structural spine whose section order is law, the element set the type earns, and the capture contract deciding what returns through the envelope. Type selection precedes any markup — the type fixes the measure, the spine, and the envelope `kind`, so two artifacts of one type read as siblings. A page serving two types splits, or one type owns the shell and the other renders as a section-scale insert; each variant resolves onto a core type the same way.

## [01]-[SELECTION]

A reader's first question selects the type; everything else on the page serves that question or leaves.

| [INDEX] | [TYPE]       | [READER_QUESTION]                    | [LAYOUT_CLASS] | [ENVELOPE_KIND] |
| :-----: | :----------- | :----------------------------------- | :------------- | :-------------- |
|  [01]   | report       | what happened and what it means      | operational    | `report`        |
|  [02]   | dashboard    | what is the state right now          | board          | none            |
|  [03]   | roadmap      | what order, and why that order       | operational    | `roadmap`       |
|  [04]   | plan         | how, stage by stage — approve or not | operational    | `plan`          |
|  [05]   | decision-doc | which option, on what grounds        | reading        | `decision`      |

A type with no envelope kind ships no drawer send section; a type with one ships the full capture grammar from the interaction reference. `kind` is closed to this table and the variant kinds below — a novel deliverable claims the nearest kind and carries its distinguishing fields under `extensions`.

## [02]-[REPORT]

A report argues a verdict from evidence; the verdict leads and the evidence descends by weight.

- [SPINE]: header triad with verdict chips baseline-beside the title; a bottom-line keyline rail stating the finding in two sentences; the metric strip (`.stat` chips with signed deltas); the evidence body; follow-ups with owners; appendix material behind `<details>`.
- [STATUS_FORM]: shipped and slipped group as separate sections, never one interleaved list; each slipped row carries its reason and its new expectation; the metric strip answers the Monday-morning skim before any scrolling.
- [INCIDENT_FORM]: a timeline spine at minute grade carries the event sequence — dot hue is state, the rail is order; the impact window is a kv ledger (`<dl class="kv">`: window, blast radius, affected surface); log and code evidence wrap as `<figure><pre><code>` with a `<figcaption>` naming the claim each excerpt proves; root cause is one section, mitigations another, and the follow-up list closes with owner per row.
- [FINDING_FORM]: an investigation or audit report renders finding cards ordered by blast radius — each card carries its anchor (`<code>` path and line), the observed fact, why it bites, and a copyable fold-back clause; a card missing its anchor is an opinion wearing a finding. Zero findings renders as a stated clean result with the probed ground listed, never an empty region.
- [CAPTURE]: a triaged report carries per-finding verdicts (`approve` folds the finding forward, `dismiss` closes it, `defer` parks it) and the fold-back copy control assembles the accepted findings into one prompt clause block; a narrative report captures nothing and drops the send section.
- [ANTI]: chronology-first narration that buries the verdict; a closing summary restating the page; severity carried by color alone without the bracket text.

## [03]-[DASHBOARD]

A dashboard answers its headline question in the default state with zero interaction; every control past that point is a lens, never a gate.

- [SPINE]: a stat row (headline numerals with trend deltas) above the fold; the primary chart region; the breakdown tables; the anomaly or exception list last — a healthy dashboard's exception list renders its authored empty state.
- [MARKS]: the page contributes the shell, the `--series-*` bindings, and the zero-baseline hairline order once chart form and palette are settled.
- [TABLES]: every table carries `<tfoot>` aggregates recomputed from visible rows; numeric columns bind `td.num`; the widest table scrolls inside its own wrapper.
- [FILTERS]: filter clusters live in `<search>`; an active filter is always visible with its match count; scope filters hide, attention filters dim — and every visible aggregate recomputes under both.
- [DENSITY]: one screen answers the standing question; a dashboard that needs a tour failed selection — the material wanted a report.
- [CAPTURE]: none. Every control is view-only chrome without capture styling; a dashboard that wants verdicts is a triage report or a board editor.
- [ANTI]: a headline metric revealed only by interaction; capture-styled controls that feed nothing; a second page of charts ranking below the fold what the stat row already states.

## [04]-[ROADMAP]

A roadmap sequences outcomes by confidence, and the page renders confidence as structure — bands, not dates.

- [SPINE]: header triad naming the destination; the horizon bands in confidence order (committed, expected, exploratory — nearest first); per-band outcome cards; the dependency figure; the promotion ledger.
- [HORIZONS]: each horizon is one band section with its confidence stated in the band header; `<time>` renders only at the precision the estimate holds — a quarter-grade claim never renders day-precise, and the exploratory band carries no dates at all.
- [CARDS]: an outcome card carries its owner and gate as a kv ledger, its promotion condition as the card's closing line — the observable that moves it one band nearer — and status chips with bracket text.
- [LANES]: parallel tracks render as grid lanes inside each band when more than one owner runs concurrently; a single-track roadmap stays one column and spends nothing on lanes.
- [DEPENDENCIES]: three or more interlinked outcomes project as one inline SVG flow figure beside the bands; the cards stay the truth the figure projects, and an edge no card carries is drift.
- [CAPTURE]: reordering within a band and dragging across bands return as `changes` rows keyed by stable outcome id; a promotion-condition edit is a field edit against the frozen baseline; the global verdict accepts or rejects the sequencing as a whole.
- [ANTI]: a dated task list wearing horizon headers — tasks are plan material; a Gantt bar implying duration certainty the band disclaims; dependency arrows carrying facts no card states.

## [05]-[PLAN]

A plan orders its sections by tweak pressure, never by execution order: the decisions most exposed to movement lead, and trusted mechanics collapse below the decision surface.

- [SPINE]: header triad with the plan's one-line thesis; the decision sections first — data shapes, interfaces, user-facing flows, each stating its chosen form and the live alternative it beat; the stage sequence; the risk table; mechanical work last, inside `<details>` per stage.
- [DECISIONS]: each leading decision renders the chosen shape as real material — a schema block, a signature, a rendered flow — never prose describing an unbuilt surface; the alternative it beat carries its one-line cost so a reviewer can reopen it deliberately.
- [STAGES]: stage cards carry `data-id`, an owner and gate kv ledger, and the stage's exit test as its closing line; a data-flow or sequence figure earns its place when three or more stages hand material to each other.
- [RISK]: risk tables cross risk by trigger by mitigation; a risk without a named observable trigger is a mood, and the table refuses it.
- [CAPTURE]: per-stage verdicts (`approve`, `defer`, `reject`) and the global decision; annotations anchor to stage ids; the fold-back copy control emits the approved plan in execution order — capture order and emission order deliberately invert, because the reviewer reads by tweak pressure and the executor reads by sequence.
- [ANTI]: a linear narrative that buries the reversible decision under stage seven; ASCII or prose diagrams where one SVG figure carries the flow; a mock described instead of rendered.

## [06]-[DECISION_DOC]

A decision doc confronts the reader with rendered rivals and returns a ruling; it is the one type whose body is the option set itself.

- [SPINE]: header triad stating the question as the deck line; the constraint frame (what any option must survive) as a keyline rail; the option grid; the scoring matrix where the choice is weighed; the ruling section; rejected options with their reopen conditions.
- [OPTIONS]: an option grid renders two to four `article.option` cards, each carrying its thesis, its cost in the same units as its rivals, a one-line tradeoff, and its evidence anchors; a visual or structural choice renders live variants — real code, real layout, judged under both themes — because taste reacts to the thing, never to its description.
- [SCORING]: criteria and weights render before any score — a matrix whose weights arrive after the scores is retrofit advocacy; heat cells cap their fill so text holds contrast at full score, and the winner signals through its `--ok` rail, never fill alone.
- [RULING]: a ruling is one indicative sentence naming the owning form, followed by its consequence; each rejected option carries the argument that lost it and the observable condition that reopens it — a rejection without a reopen condition reads as dogma.
- [CAPTURE]: per-option verdicts, the pick, per-criterion score edits, and steal-selections — the chips marking fragments of a losing option that fold into the winner; the envelope's `decision.status` carries the pick and the markdown form leads with the ruling.
- [ANTI]: a single proposition offered for ratification — agree-or-disagree harvests acquiescence; a recommendation with no rendered rival; options whose costs are stated in different units so nothing compares.

## [07]-[VARIANTS]

Each variant resolves onto a core type and earns only its named deltas; everything unstated inherits from the base row.

| [INDEX] | [VARIANT]     | [BASE]       | [ENVELOPE_KIND] |
| :-----: | :------------ | :----------- | :-------------- |
|  [01]   | diff-review   | report       | `diff`          |
|  [02]   | quiz          | decision-doc | `quiz`          |
|  [03]   | wargame       | decision-doc | `decision`      |
|  [04]   | buy-in        | report       | `buyin`         |
|  [05]   | explainer     | report       | none            |
|  [06]   | contact-sheet | dashboard    | none            |
|  [07]   | board         | dashboard    | `board`         |
|  [08]   | atlas         | roadmap      | `report`        |
|  [09]   | deck          | any          | inherits base   |
|  [10]   | editor        | plan         | `plan`          |
|  [11]   | walkthrough   | report       | none            |
|  [12]   | prototype     | dashboard    | none            |

- diff-review: rendered diff with margin annotations and severity chips, file-level risk labels; per-hunk verdicts anchored to stable hunk ids.
- quiz: three homogeneous choices, per-answer justification, criterion readout with no percentage; one receipt carries every selection.
- wargame: scoring matrix at board width, weights locked before scores, one row per direction; kill conditions as row chips.
- buy-in: inspectable evidence — demo, trace, before-and-after — one objection lane per audience; refutation and proving signal, a sign-off matrix as capture.
- explainer: reading class, contrasting cases side by side, scrub controls driving a live figure; hover-linked term glossary, disclosure deepens and never gates.
- contact-sheet: stage class, variant matrix under shared controls, best-for label per cell; density, border, and state toggles, both themes rendered rather than imagined.
- board: drag cards across named columns, dependency warnings on invalid placement; changed-only export of moved ids, DOM position never authoritative.
- atlas: entity cards, edge lists, maturity chips, one SVG relation figure over 3+ edges; refused arms distinguished from gaps by bracket text.
- deck: full-viewport slide shell over the same payload and drawer, arrow-key state machine; slide counter always rendered, per-slide reading width.
- editor: disposable field editor over one payload, controls bound one-to-one to fields; invalid-combination warnings from declared rules, changed-only export.
- walkthrough: reading class, request path or callstack as a numbered step rail on one flow figure; source excerpts keyed to steps, a key-files table, gotchas close.
- prototype: stage class, linked screens under `data-step` nav or a timed micro-interaction; live timing controls with replay, fake data declared as fake.

- A variant page keeps its base type's spine inside the variant shell: a deck of plan stages still orders decisions before mechanics; a wargame still states its constraint frame before any direction renders.
- A diff-review's author-side writeup form leads motivation and before-and-after evidence with a file tour ordered by review focus; a prototype spends fidelity only where the judgment needs it.
- Two-way flow is the default posture for every capturing variant: the page is a disposable editor for exactly the judgment it collects, and the copy-as-prompt control is the floor when no return channel serves it.
- Work larger than one page ships as a sibling chain — exploration, then prototype, then plan, then verification — each page one type linked by relative links, the chosen option collapsing forward into the next page; one page serving the whole chain is the two-type defect at chain scale.
