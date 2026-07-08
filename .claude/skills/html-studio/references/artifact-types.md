# [ARTIFACT_TYPES]

A type is a fixed region order composing baseline tokens and named interaction patterns under one export rule. Each type answers a fixed interrogation, and the region spine is the shape that answers it; each row also names the misfit sibling it displaces, so the most specific trigger wins. A type that captures or edits intent carries the export drawer and probes the return channel per [roundtrip.md](roundtrip.md); a purely narrative type carries only its disk-egress section. Per-type controls land in the drawer's fields section — verdict selects, score inputs, note textareas, the readonly mirror — in the fixed order after send and disk egress. Diagram construction routes to [svg.md](svg.md); the element generators route to [elements.md](elements.md); every visual token routes to [design-system.md](design-system.md). A request no row matches composes the nearest spine rather than falling back to markdown.

Every control on a type lands in exactly one of three classes. Load-bearing controls mutate the return envelope and name their field from the capture classes [roundtrip.md](roundtrip.md) owns; a new capture class lands there as one class row plus the per-type rows here that adopt it. View-only controls change presentation and write nothing: theme, collapse, TOC, deep-link, tabs, filter-dim, sort, keyboard nav, and escape-render are universal conveniences, never per-type decisions and never load-bearing. Forbidden controls are toys that imply capture but feed nothing; each type names its own. A narrative type renders no load-bearing control and no send action.

[01]-[PLAN]:

- Question: what changes, in what order, and what proves each stage complete.
- Displaces: brainstorm — the direction is chosen; the page hands off execution.
- Regions, in order:
  - Header — eyebrow, title, deck line, one status chip.
  - Summary strip — four stat cells derived live from the model: phase and stage completion, open-question count, top risk exposure.
  - Sticky TOC — anchors per section, active section highlighted.
  - Decision surface — the tweakable decisions ranked by blast radius, each with ruling, rationale, state chip, and verdict capture; the decisions a reviewer most plausibly flips sit first, above the execution sequence, and mechanical work stays collapsed below them.
  - Phase spine — a dependency spine of independently reviewable phases with done/active/blocked dots and live completion, each phase carrying its stages, acceptance signals, and dependency chips.
  - Data flow — one inline-SVG figure separating request/response from async fan-out, present when the change crosses a process or wire seam.
  - Key code — collapsible panels reserved for the error-prone parts only.
  - Risk register — table of risk, severity chip, concrete mitigation.
  - Open questions — each with decision owner and decision deadline.
- Load-bearing: per-decision and per-stage verdicts feed `decisions[]{id,verdict}`; a stage status override lands in `changes[]{itemId,path,from,to}`; an open-question answer lands in `changes[]` and its note in `annotations[]{itemId,intent}`.
- View-only: theme toggle, deep-link, collapsible key-code, TOC.
- Forbidden: a progress slider on a stage — progress is an agent fact, never a human dial; a stage drag-reorder that emits no `changes[]` position.
- Export: required-when-captured — stages, verdicts, and acceptance as markdown plus the envelope.
- Review: acceptance that names no observable signal, so a stage stays unprovable.

[02]-[BRAINSTORM]:

- Question: which genuinely distinct directions exist and what tips the choice — candidates unnamed until this page names them.
- Displaces: wargame — nothing is scoreable until directions exist; inline option chips — a visual comparison never flattens to a chip row.
- Regions, in order:
  - Header — eyebrow, title, direction count, the prompt block quoting the ask.
  - Direction grid — three to six cards, each RENDERING its option (live variant, code excerpt, layout mock) with a posture label and tradeoff line; each direction takes a distinct treatment while the grid stays structurally parallel.
  - Comparison control — highlights one criterion across every card at once.
  - Verdict footer — the leaning direction and the trigger that flips it.
- Load-bearing: per-direction verdict chips feed `decisions[]{id,verdict}`; stolen fragments compose `state.hybrid`; the leaning and its flip trigger land in `state.leaning` and an `annotations[]` row.
- View-only: theme toggle, filter, deep-link, criterion-lift highlight.
- Forbidden: a live variant control inside a direction card that mutates the rendered option but never records which variant was chosen.
- Export: required — kept directions, hybrid, and flip trigger as markdown; send-to-agent when the channel is live.
- Review: directions collapsing onto one axis, so the comparison decides nothing.

[03]-[ROADMAP]:

- Question: what lands in which horizon, what each outcome hard-depends on, and where it stands today.
- Displaces: plan — horizons are confidence bands, never dated task lists.
- Regions, in order:
  - Header — eyebrow, title, scope chip, date slot, live overall chip deriving on-track or at-risk from the dependency graph.
  - Horizon timeline — one banded inline-SVG figure: milestone diamonds by status, dashed dependency arcs drawn only for cross-horizon hard dependencies (a backward dependency renders in `--fail`), a today marker from the roadmap date.
  - Rollup — one card per horizon counting done, active, open, and at-risk milestones.
  - Horizon lanes — one lane per horizon holding milestone cards; each card carries owner, dependency roster, derived at-risk reason, and a status/note override; the hard-dependency critical chain draws at emphasis weight with slack rendered as lighter buffer extensions.
  - Filter box — live-dims cards by text; counts stay visible.
- Narrow viewports collapse the horizontal timeline into stacked dated cards per horizon — never cramped bars.
- Load-bearing: a bar or card dragged across horizons is the replan signal — `changes[]{itemId,path:"/milestones/{id}/horizon",from,to}`; a status override or promotion-condition edit lands in `changes[]`; a milestone note in `annotations[]`.
- View-only: theme toggle, filter-dim with visible counts, click-to-detail, today marker, deep-link.
- Forbidden: a time-axis zoom that rescales and writes nothing yet reads as interaction; dragging a dependency arrow — dependencies are structure, edited as data or not at all.
- Export: required-when-captured — the horizon map plus every move as markdown and envelope.
- Review: a dependency drawn forward across horizons, so the sequence cannot hold.

[04]-[WARGAME]:

- Question: how each named option scores under the weights, which wins, and how the winner breaks.
- Displaces: brainstorm — candidates are named; the page evaluates, never generates.
- Regions, in order:
  - Header — eyebrow, title, criteria legend with live weight sliders.
  - Scoring matrix — options as rows, criteria as columns, heatmap cells whose fill intensity tracks score, editable values with a rationale slot per cell, a live weighted-total column.
  - Hard requirements — pass/fail rows that disqualify a candidate regardless of weighted total; a disqualified row keeps its scores, takes the `--fail` rail with its reason inline, and the verdict pane never crowns it.
  - Verdict pane — reranks as weights move; carries the sensitivity line as a computed threshold: the named weight or score change that flips the winner (`X wins once criterion Y ≥ N%`).
  - Risk cards — one card per option enumerating failure modes.
- Load-bearing: weight sliders feed `changes[]` weight rows and the re-rank; editable score and rationale cells feed `changes[]{itemId:"{option}/{criterion}",from,to}`; the final call and dissent feed `decision.status` and `state.global`.
- View-only: theme toggle, heatmap intensity, risk-card layout.
- Forbidden: a slider bound to no criterion; a total read from the DOM instead of recomputed from weights.
- Export: required — scored matrix, weights, sensitivity, and verdict as markdown plus JSON; send-to-agent when live.
- Review: totals that ignore the weights, so the winning row is an arithmetic accident.

[05]-[DIFF_REVIEW]:

- Question: what the patch changes, where the risk sits, and whether it merges.
- Displaces: explainer — the code is the evidence, never a narrative about it.
- Regions, in order:
  - Header — repo line, title, author, branch, delta counts.
  - Risk map — severity chips per file doubling as the TOC; clicking scrolls and flash-highlights the file card.
  - File cards — diff rows in a line-number/sign/code grid, margin annotations under forty words anchored to their lines with severity rails; safe files collapse to a summary row.
  - Next steps — a checklist of the blocking findings.
  - Verdict footer — merge posture.
- Load-bearing: per-finding verdict votes feed `decisions[]{id,verdict}` and reply notes feed `annotations[]`; the reviewed checkbox per file feeds `changes[]`; a posture override with reason feeds `decision.status`.
- View-only: theme toggle, escape render, anchor flash, collapsible safe files, deep-link.
- Forbidden: a merge button that implies action — the artifact captures posture, the agent merges; a finding checkbox wired to nothing.
- Export: required — the review envelope plus a clarified-review markdown.
- Review: unescaped source reaching the DOM, so the patch text renders as live markup.

[06]-[QUIZ]:

- Question: does the reader grasp the change, its risk, its tests, and its edge cases.
- Displaces: diff-review — comprehension is gated, never assumed from a read.
- Regions, in order:
  - Header — title, change reference, live score slot.
  - Question cards — one per question, choices as inputs, per-answer reveal explaining the correct choice only after selection.
  - Section links — each wrong answer links the owning corpus page.
  - Score bar — live score, serialized on export, restored on re-import.
- Load-bearing: answer selection feeds `state.answers{}` and per-question outcomes; the final score contextualizes `decision.status`.
- View-only: theme toggle, reveal-after-choice, section links, deep-link.
- Forbidden: a reveal that leaks before choice; a score the human can dial — score is computed, never set.
- Export: required — score and per-question outcome as markdown, re-importable; send-to-agent when live.
- Review: a reveal leaking the answer before the choice, so comprehension goes untested.

[07]-[BUY_IN]:

- Question: what was built, what it asks for, and what answers each objection.
- Displaces: explainer — the page persuades a named audience, never walks a mechanism.
- Regions, in order:
  - Header — title, one-line thesis, date slot.
  - Demo lead — the strongest artifact or result first.
  - Objection cards — one per anticipated objection paired with its answer; one lane per audience in a multi-audience variant.
  - Ask and tradeoff list — the decision requested and the costs named.
  - Sign-off list — named approvers, one state chip each.
- Load-bearing: per-approver sign-off state feeds `decisions[]{id,verdict}`; an objection response feeds `annotations[]`.
- View-only: theme toggle, deep-link, audience-lane tabs.
- Forbidden: a sign-off chip that flips visually but feeds no decision row.
- Export: required — a shareable sign-off message as markdown plus the envelope.
- Review: an objection answered softly, so the strongest counter goes unnamed.

[08]-[CAPABILITY_ATLAS]:

- Question: what owners exist, what each operates, and how they stack.
- Displaces: roadmap — the atlas maps standing capability, never sequences it.
- Regions, in order:
  - Header — title, surface name, date slot.
  - Sticky TOC — anchor per owner group.
  - Owner sections — a grid of capability cards stating operation, input shape, output; a module-map variant adds entry, state, boundary, failure, and gotcha cards with exact file and member names.
  - Composition map — inline-SVG node-and-edge figure of owner stacking per [svg.md](svg.md).
  - Coverage table — capability against status chip.
- Load-bearing: only when the atlas requests coverage judgment — a capability status verdict feeds `decisions[]`; otherwise the type is narrative and carries no send.
- View-only: theme toggle, filter, flow highlight, node click-to-detail, keyboard nav, per-figure SVG download.
- Forbidden: a node drag that rearranges the topology and writes nothing.
- Export: optional-with-form — the owner-and-operation map as markdown; the stage as standalone SVG.
- Review: an edge map with no legible path, so composition reads as a tangle.

[09]-[EXPLAINER]:

- Question: what the mechanism does, why it holds, and where its caveats bite.
- Displaces: wargame — the decision is settled; the page teaches it.
- Feature variant, regions in order:
  - Sticky side nav — section anchors plus a files-read list.
  - Header — title with a TL;DR rail stating the whole answer in three sentences.
  - Path steps — collapsible steps each carrying its exact file locator.
  - Tabbed samples — config, call site, and observed response as tab panes.
  - Gotchas — keyline callouts for the operational traps.
  - FAQ — recurring questions with settled answers.
- Concept variant, regions in order:
  - Header — title, the concrete instance the concept explains.
  - Live simulator — a manipulable inline-SVG model with controls and a readout computing the consequence of each change.
  - Glossary rail — sticky definitions; prose terms hover-link their entries.
  - Comparison table — the concept against its naive alternative, weak cells marked.
  - Where-it-lands — the surfaces in this corpus that carry the concept.
- Narrative: all controls are view-only — theme toggle, collapsible steps, tabs, glossary hover-link, the simulator scrub whose live readout is the learning, deep-link. No send action renders.
- Forbidden: any capture-styled control; interaction that hides the settled conclusion behind a gesture.
- Export: optional-with-form — the section outline as markdown.
- Review: interaction that hides the conclusion, so the settled decision stays buried.

[10]-[DECK]:

- Question: what the case is, in what order it lands, and where the argument stands per slide.
- Displaces: explainer — the reader is walked, one section at a time, under keyboard control.
- Regions, in order:
  - Slide sections — one full-viewport `<section>` per slide under `scroll-snap-type:y mandatory`, hero type on a clamp scale, one inverted slide for the decision beat.
  - Nav — ArrowRight/ArrowLeft/Space advance; an `IntersectionObserver` drives the fixed counter and progress.
  - Presenter aside — per-slide notes in an `<aside>` toggled by one key, hidden in present mode.
- Load-bearing: per-slide flag and note feed `annotations[]{itemId,intent}` — the reader's objections travel back with the outline.
- View-only: theme toggle, deck keys, notes toggle, counter, deep-link.
- Forbidden: a reaction control that animates but records nothing.
- Export: optional-with-form — a slide outline plus flagged slides as markdown; send-to-agent when live.
- Review: argument fragmentation, so slides stop composing one case.

[11]-[EDITOR]:

- Question: what state stands after the edit, what changed from the baseline, and what leaves as the record.
- Displaces: plan — the reader adjusts the artifact instead of reading a fixed one.
- One polymorphic type; the modality is a data-model row, never a sibling file:
  - board — columns and draggable cards; drop mutates the card's column field; per-column counts and totals derive live.
  - config — grouped toggles with dependency warnings surfacing inline and in a banner; the sidebar renders only changed keys.
  - prompt — a caret-preserving contenteditable template with slot highlighting, unknown-slot warnings, and live sample previews.
  - dataset — row curation with keep/cut marks, tag filters that dim, and a detail drawer.
  - annotation — spans or regions marked with a closed verdict vocabulary.
  - graph — nodes and typed edges edited in place: add child or sibling, relabel, re-parent by drag, prune; tree layouts (radial, horizontal, vertical) or a small fixed graph, per [svg.md](svg.md); the model is the adjacency list and exports as outline, JSON tree, or edge list.
- Regions, in order: header; sticky toolbar (filters, reset); the modality surface; changed-state diff against a frozen initial snapshot; export drawer.
- Load-bearing by modality, all against a frozen `structuredClone` baseline: a board drop feeds `changes[]{itemId,path:"/cards/{id}/col"}`; a config toggle feeds `changes[]{itemId,path,from,to}`; a prompt slot edit feeds `state.template`; a dataset keep/cut feeds `decisions[]`; annotation spans feed `annotations[]`; a graph mutation feeds `changes[]` keyed by node id with the full adjacency in `state`.
- View-only: theme toggle, tag filter-dim, detail drawer, reset-to-baseline.
- Forbidden: any control reading final state from the DOM — export derives from the model; a reset that clears the draft but not the baseline diff.
- Export: required — the durable artifact (markdown board, config diff plus full JSON, prompt text, curated rows), never a UI-state dump; send-to-agent when live.
- Review: state read from the DOM, so the export forks from the true model.

[12]-[DESIGN_SYSTEM]:

- Question: what tokens exist, what each is for, and how a component reads across its states.
- Displaces: explainer — every token renders as the applied decision it is.
- Regions, in order:
  - Header — title, token-source name, date slot.
  - Swatch grid — one card per color token: name, value, intended use, contrast note, failure use.
  - Type scale — live specimens at each step with size, leading, and weight beside each.
  - Spacing and shape — spacing tokens as measured bars, radii and elevation as physical cards.
  - Component contact sheet — each primitive across size, intent, state, density, and theme.
- Narrative-leaning: view-only theme toggle, filter, keyboard nav, per-token copy.
- Forbidden: a knob that changes no rendered behavior — the sheet drifts into decoration.
- Export: optional-with-form — the token roster as markdown or JSON.
- Review: a knob that changes no behavior, so the sheet drifts into decoration.

[13]-[REPORT]:

- Question: what the state is, what the evidence shows, and what it asks for next.
- Displaces: explainer — the page recurs on a cadence and is skimmed before read.
- Status variant, regions in order:
  - Header — title, period, auto-generated chip.
  - KPI band — stat cards with serif numerals and delta pills; the warning card takes a status rail.
  - Highlights — three keyline entries stating what moved.
  - Shipped table — evidence rows with links, owners, risk chips.
  - Velocity chart — one inline-SVG plot with the peak highlighted.
  - Carryover — tagged rows naming what slipped and why.
- Incident variant, regions in order:
  - Header — incident id, severity and resolution pills, duration, owner.
  - TL;DR — an inverted panel stating cause, impact, and mitigation in four sentences.
  - Timeline spine — minute-stamped dots with impact and mitigated states, ordered by causality.
  - Root cause — prose plus the config or code diff that carried the defect.
  - Impact table — failed requests, error rate, users, data loss, breach status.
  - Action items — owner avatar, due date, done state per row.
- Narrative: all controls are view-only — theme toggle, collapsible, deep-link, copy digest. A report is skimmed and digested, never adjusted; a report that asks for input is a different type — a review or a plan.
- Export: optional-with-form — asks and digest as markdown.
- Review: causality out of order, so the timeline hides what drove the outcome.

[14]-[DASHBOARD]:

- Question: what the numbers say, how they move under a filter, and which rows drive them.
- Displaces: report — the reader interrogates the dataset instead of receiving a digest.
- Regions, in order:
  - Header — title, filter and facet controls with live match counts; facets compose OR within a facet and AND across facets, every facet value shows its count under the active filter, the active-filter tally stays visible, and one control clears all.
  - Embedded dataset — the JSON payload inlined and sanitized per [state.md](state.md); the secret-redaction gate runs before embedding; pre-aggregate past ten-thousand rows.
  - KPI row — stat cards recomputed under the active filter.
  - Charts — inline-SVG plots reading series tokens.
  - Data table — sortable rows; filters dim nonmatching rows rather than removing them; clicking a row opens a detail drawer.
- Load-bearing: none by default — a dashboard is interrogation; it becomes capturing only when the reader marks rows for action, and a row flag verdict plus note feeds `decisions[]` and `annotations[]`; only then does the send action render.
- View-only: theme toggle, filter, facet, sort, detail drawer, keyboard nav — narrowing never removes from the model or the export.
- Forbidden: a filter that deletes rows from the export — the export is the full payload plus the filtered view, never a filtered-down model.
- Export: required — the filtered view as markdown plus the full JSON envelope.
- Review: totals that ignore the filter, so a KPI lies against the visible rows.

[15]-[CONTACT_SHEET]:

- Question: how one thing reads in each state, which cells to keep, and what the kept set assembles into.
- Displaces: brainstorm — states of one thing, never competing directions.
- Regions, in order:
  - Header — title, specimen axis legend, date slot.
  - Specimen grid — one cell per size × intent × state × density × theme, same scale and grammar across cells.
  - Selection chips — a steal or skip chip per cell marking the kept set.
  - Assembly footer — the selected cells composed into one surface.
- Load-bearing: a steal or skip chip per cell feeds `decisions[]{id,verdict}` marking the kept set; the assembly composes from kept cells into `state`.
- View-only: theme toggle, filter, keyboard nav.
- Forbidden: a kept-set that reads from chip DOM state instead of the model.
- Export: required — the selected assembly as markdown or JSON; send-to-agent when live.
- Review: cells drawn at different scales, so difference reads as noise, not signal.

[16]-[PROTOTYPE]:

- Question: how the interaction feels before it is built, and what stays open.
- Displaces: brainstorm — one direction is felt, never several compared.
- Animation variant, regions in order:
  - Stage — the real component running its micro-interaction on click.
  - Easing panel — selectable curves mutating one runtime custom property.
  - Keyframe timeline — every staged sub-motion labeled with its exact delay.
  - Copy panel — the tuned CSS as a copyable specimen.
- Interaction variant, regions in order:
  - Working surface — the interaction live: drag, reorder, toggle, with full state cleanup.
  - Decision annotations — the feel decisions baked in, stated so the reader can push back.
  - Open questions — the unresolved feel questions beside the working control.
- Load-bearing: tuned easing and timing values feed `state.tuning`; open-question answers feed `decisions[]` with notes.
- View-only: theme toggle, the running micro-interaction, scrub.
- Forbidden: mistaking the fidelity control for a build knob — the copy panel emits values as feedback, never authoritative config.
- Export: required — the tuned values plus answered questions as markdown and envelope; send-to-agent when live.
- Review: fidelity mistaken for architecture, so the mock reads as a build spec.

[17]-[FIGURE_SHEET]:

- Question: which standalone vector figures the document set needs, each ready to lift.
- Displaces: capability-atlas — the figures serve external documents, never this page's argument.
- Regions, in order:
  - Header — title, canvas dimensions, the no-external-asset line.
  - Figure cards — one per figure: inline SVG with its own embedded `<style>`, caption naming the destination document, a per-figure download button serializing that SVG alone.
  - Palette and rules footer — the locked swatches and stroke/radius/label rules the figures obey.
- Narrative: view-only theme toggle; the per-figure download is the deliverable, not a capture.
- Forbidden: a figure whose labels depend on page CSS, so the download renders unstyled.
- Export: required — each figure as a standalone `.svg` per [svg.md](svg.md).
- Review: a figure whose labels depend on page CSS, so the download renders unstyled.

[18]-[ARCHITECTURE]:

- Question: how the system's parts relate and how each named behavior moves across them.
- Displaces: capability-atlas — one full-bleed topology with live flows, never sectioned cards.
- Regions, in order:
  - Control bar — title, theme toggle, one chip per named flow.
  - Stage — the SVG topology filling the remaining viewport: dashed zone rectangles, typed nodes, directed edges with token-fed markers.
  - Detail card — floating panel filled from a detail map when a node is clicked.
  - Flow caption — floating panel walking the selected flow's ordered steps.
- Interaction: flow chips dim everything then light the selected path with animated dash offset; reduced-motion stills the dashes; click-to-detail per node. Construction law is [svg.md](svg.md).
- Export: optional — the stage as a standalone SVG.
- Review: two behaviors drawn as two topologies, so the reader reconciles diagrams instead of flows.

[19]-[SCHEMA_MAP]:

- Question: what entities exist, how they relate, and what a change does to the shape.
- Displaces: architecture — tables and keys are the subject, never services and flows.
- Regions, in order:
  - Header — title, store name, entity and relation counts.
  - Entity canvas — table cards carrying column rows (name, type, key marker, nullability, index badge) laid out by domain grouping past eight tables; FK edges run child to parent with crow's-foot cardinality marks, junction tables render smaller between their principals, and external references fade as context cards.
  - Focus rail — clicking a table lights its relation neighborhood and dims the rest; a name filter narrows; a show-only-related toggle prunes the canvas.
  - Migration band — present only for a schema change: current/target/diff states toggle in place, added columns in `--ok`, removed in `--fail`, changed in `--warn`, and a changed column's click reveals its rationale.
  - Query paths — present only when specific queries are the subject: selecting a named query lights the tables, joins, and indexes it touches.
- Load-bearing: only when the map requests judgment — a per-change verdict on a migration diff feeds `decisions[]`; otherwise the type is narrative and carries no send.
- View-only: theme toggle, focus fade, filter, migration state toggle, query-path highlight, per-figure SVG download.
- Forbidden: a table drag that rearranges the canvas and writes nothing; an FK drawn by gesture — relations are data, edited as data or not at all.
- Export: optional-with-form — the entity-relation roster as markdown; the canvas as standalone SVG.
- Review: a relation edge whose cardinality contradicts the column keys, so the map lies about the schema.
